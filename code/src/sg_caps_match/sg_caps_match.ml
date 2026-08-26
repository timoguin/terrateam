let is_negation s = CCString.prefix ~pre:"!" s
let dedup l = CCList.sort_uniq ~cmp:CCString.compare l

(* A capability pattern, after any leading ['!'], is a literal prefix with an optional single
   trailing ['*']. The prefix is a raw character prefix (not segment/dot-aligned), so ["aws_*"] and
   ["foo*"] are valid and match ["aws_instance"]/["foobar"]. [parse_glob] returns the literal prefix
   and whether a trailing ['*'] is present, or [None] when the string is not a well-formed
   prefix-glob (a ['*'] anywhere but the end, or more than one ['*']). *)
type glob = {
  prefix : string;
  wild : bool;
}

let parse_glob s =
  match CCString.index_opt s '*' with
  | None -> Some { prefix = s; wild = false } (* exact literal *)
  | Some i when i = CCString.length s - 1 -> Some { prefix = CCString.sub s 0 i; wild = true }
  | Some _ -> None (* ['*'] not last, or a second ['*'] precedes it *)

let max_pattern_length = 256

(* [is_valid_pattern s] gates untrusted input: a bounded-length, well-formed prefix-glob (optionally
   negated). A ['*'] is allowed ONLY as the final character; a mid-string ['*'] (e.g. ["a*b"],
   ["*.foo"], ["foo.*.bar"]) or a repeated ['*'] (e.g. ["a**"]) is rejected. *)
let is_valid_pattern s =
  CCString.length s <= max_pattern_length
  && CCOption.is_some (parse_glob (if is_negation s then CCString.drop 1 s else s))

(* [subsumes a b] is true when every value matched by [b] is also matched by [a] (L(b) ⊆ L(a)).
   ["p*"] covers exactly the strings beginning with [p]; an exact literal covers only itself.
   Returns [false] for patterns that are not well-formed prefix-globs, so nothing is dropped on
   their account. *)
let subsumes a b =
  match (parse_glob a, parse_glob b) with
  | Some a, Some b ->
      if a.wild then CCString.prefix ~pre:a.prefix b.prefix
      else (not b.wild) && CCString.equal a.prefix b.prefix
  | _ -> false

(* [intersects a b] is true when some value is matched by both [a] and [b] (L(a) ∩ L(b) <> empty).
   Two ["p*"] overlap iff one prefix starts the other; a ["p*"] and an exact literal overlap iff the
   literal starts with [p]; two literals overlap iff equal. Returns [true] for patterns that are not
   well-formed prefix-globs (assume overlap), so a negation is never dropped as "disjoint" on their
   account. *)
let intersects a b =
  match (parse_glob a, parse_glob b) with
  | Some a, Some b -> (
      match (a.wild, b.wild) with
      | true, true ->
          CCString.prefix ~pre:a.prefix b.prefix || CCString.prefix ~pre:b.prefix a.prefix
      | true, false -> CCString.prefix ~pre:a.prefix b.prefix
      | false, true -> CCString.prefix ~pre:b.prefix a.prefix
      | false, false -> CCString.equal a.prefix b.prefix)
  | _ -> true

(* [reduce_subsumed l] removes every entry a different entry subsumes, leaving only the broadest
   globs. When two entries subsume each other (e.g. ["*"; "**"]) the earlier is kept, so exactly one
   survives. Correctness does not depend on input order. *)
let reduce_subsumed l =
  let indexed = CCList.mapi (fun i g -> (i, g)) l in
  let subsumed_by_another (i, g) =
    CCList.exists (fun (j, h) -> i <> j && subsumes h g && (j < i || not (subsumes g h))) indexed
  in
  indexed |> CCList.filter (fun e -> not (subsumed_by_another e)) |> CCList.map snd

let normalize_list = function
  | [] -> []
  | l when CCList.for_all is_negation l -> "*" :: l
  | l -> l

(* Mirror of [Sg_node.Matcher.glob_to_lua_pattern]: ['*'] becomes [.*], every Lua-pattern
   metacharacter is escaped, and the result is anchored so the whole string must match. *)
let glob_to_lua_pattern glob =
  let buf = Buffer.create (CCString.length glob * 2) in
  Buffer.add_char buf '^';
  CCString.iter
    (fun c ->
      match c with
      | '*' -> Buffer.add_string buf ".*"
      | '(' | ')' | '%' | '[' | ']' | '+' | '-' | '?' | '^' | '$' | '.' ->
          Buffer.add_char buf '%';
          Buffer.add_char buf c
      | c -> Buffer.add_char buf c)
    glob;
  Buffer.add_char buf '$';
  Buffer.contents buf

let glob_matches glob value =
  match Lua_pattern.of_string (glob_to_lua_pattern glob) with
  | Some t -> CCOption.is_some (Lua_pattern.find value t)
  | None -> false

let matches patterns value =
  let patterns = normalize_list patterns in
  let negs, poss = CCList.partition is_negation patterns in
  let any l = CCList.exists (fun g -> glob_matches g value) l in
  any poss && not (any (CCList.map (CCString.drop 1) negs))

let canonicalize_list l =
  let negs, poss = CCList.partition is_negation l in
  let negs = reduce_subsumed (dedup negs) in
  let poss = reduce_subsumed (dedup poss) in
  if CCList.exists (CCString.equal "!*") negs then [ "!*" ]
    (* a "!*" excludes everything -> deny all *)
  else if CCList.is_empty poss then
    if CCList.is_empty negs then [ "!*" ] (* [] -> deny all *)
    else "*" :: negs (* genuine all-negation input: materialize the implicit "*" *)
  else
    let body n = CCString.drop 1 n in
    (* cross-polarity 1: drop positives that some negation fully excludes *)
    let poss =
      CCList.filter (fun p -> not (CCList.exists (fun n -> subsumes (body n) p) negs)) poss
    in
    if CCList.is_empty poss then [ "!*" ]
      (* every positive was excluded -> deny all.  NOT the all-negation "*"-materialization, which
         would WIDEN: e.g. ["a.*"; "!a.*"] denies all -> must be ["!*"], never ["*"; "!a.*"]. *)
    else
      (* cross-polarity 2: drop negations disjoint from every remaining positive (dead excludes) *)
      let negs =
        CCList.filter (fun n -> CCList.exists (fun p -> intersects (body n) p) poss) negs
      in
      poss @ negs

let grants_all patterns =
  let negs, poss = CCList.partition is_negation (normalize_list patterns) in
  CCList.is_empty negs && CCList.exists (CCString.equal "*") poss

let lookup assoc key =
  CCOption.or_lazy (CCList.assoc_opt ~eq:CCString.equal key assoc) ~else_:(fun () ->
      CCList.assoc_opt ~eq:CCString.equal "*" assoc)
