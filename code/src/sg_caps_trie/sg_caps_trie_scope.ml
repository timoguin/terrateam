type t = bool Sg_caps_trie.t

let empty = Sg_caps_trie.const false
let full = Sg_caps_trie.const true

(* [Sg_caps_trie.of_rules] keeps the order of rules with the same specificity, and the last rule of
   a pattern wins. Putting the refusals after the allowances makes a refusal win. *)
let of_rules rules =
  CCList.stable_sort (fun (_, a) (_, b) -> CCBool.compare b a) rules
  |> Sg_caps_trie.of_rules ~equal:CCBool.equal ~default:false

let to_rules = Sg_caps_trie.to_rules ~equal:CCBool.equal ~default:false
let mem = Sg_caps_trie.find
let union = Sg_caps_trie.merge ~equal:CCBool.equal ( || )
let inter = Sg_caps_trie.merge ~equal:CCBool.equal ( && )
let diff = Sg_caps_trie.merge ~equal:CCBool.equal (fun a b -> a && not b)
let compl = Sg_caps_trie.map ~equal:CCBool.equal not
let is_empty = Sg_caps_trie.for_all not
let is_full = Sg_caps_trie.for_all CCFun.id
let entails a b = is_empty (diff b a)

(* A set is finite when no rule allows a prefix. Its strings are then the literals it allows. *)
let literals t =
  let rules = to_rules t in
  let allows_a_prefix = function
    | Sg_caps_trie.Pattern.Prefix _, allowed -> allowed
    | Sg_caps_trie.Pattern.Literal _, _ -> false
  in
  let allowed_literal = function
    | Sg_caps_trie.Pattern.Literal s, true -> Some s
    | Sg_caps_trie.Pattern.Literal _, false | Sg_caps_trie.Pattern.Prefix _, _ -> None
  in
  if CCList.exists allows_a_prefix rules then `Infinite
  else `Literals (CCList.filter_map allowed_literal rules)

let of_strings texts =
  let open CCResult.Infix in
  CCResult.map_l
    (fun text ->
      match CCString.chop_prefix ~pre:"!" text with
      | Some refused ->
          (* A rule starting with ! is a refusal *)
          Sg_caps_trie.Pattern.of_string refused >|= fun p -> (p, false)
      | None -> Sg_caps_trie.Pattern.of_string text >|= fun p -> (p, true))
    texts
  >|= of_rules

let to_strings t =
  CCList.map
    (fun (p, allowed) -> (if allowed then "" else "!") ^ Sg_caps_trie.Pattern.to_string p)
    (to_rules t)

let equal = Sg_caps_trie.equal CCBool.equal
let pp = Sg_caps_trie.pp Format.pp_print_bool
