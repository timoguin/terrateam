module Ctx = struct
  type t = {
    dirspace : Terrat_dirspace.t;
    working_dirspace : Terrat_dirspace.t option;
  }

  let make ?working_dirspace ~dirspace () = { dirspace; working_dirspace }
end

module Q = struct
  type t =
    | Or of (t * t)
    | And of (t * t)
    | Tag of string
    | Dir_glob of (string * ((string -> bool)[@opaque]))
    | Not of t
    | Any
  [@@deriving show]
end

type warning = Implicit_and of { suggestion : string option } [@@deriving show]

type t = {
  s : string;
  q : Q.t;
  warning : warning option;
}
[@@deriving show]

let equal { s = s1; _ } { s = s2; _ } = CCString.equal s1 s2
let dir_in_prefix = "dir~"
let dir_in_prefix_len = CCString.length dir_in_prefix
let dir_prefix = "dir:"

let escape_glob s =
  let b = Buffer.create (CCString.length s) in
  CCString.iter
    (function
      | ('a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' | '-' | '.' | ' ' | '/') as c ->
          Buffer.add_char b c
      | c ->
          Buffer.add_char b '\\';
          Buffer.add_char b c)
    s;
  Buffer.contents b

let rec process_dot_dot fname =
  match CCString.Split.left ~by:"/../" fname with
  | Some (l, r) -> (
      match CCString.Split.right ~by:"/" l with
      | Some (l', _) -> process_dot_dot (l' ^ "/" ^ r)
      | None -> process_dot_dot r)
  | None -> fname

let test_relative_dir ctx relative_dir =
  match ctx.Ctx.working_dirspace with
  | Some working_dirspace ->
      CCString.equal
        ctx.Ctx.dirspace.Terrat_dirspace.dir
        (process_dot_dot (Filename.concat working_dirspace.Terrat_dirspace.dir relative_dir))
  | None -> false

let rec match' ~ctx ~tag_set = function
  | Q.Any -> true
  | Q.Not t -> not (match' ~ctx ~tag_set t)
  | Q.Tag tag -> (
      match CCString.Split.left ~by:":" tag with
      | Some ("relative_dir", relative_dir) -> test_relative_dir ctx relative_dir
      | _ -> Terrat_tag_set.mem tag tag_set)
  | Q.Dir_glob (_, eq) -> eq ctx.Ctx.dirspace.Terrat_dirspace.dir
  | Q.And (l, r) -> match' ~ctx ~tag_set l && match' ~ctx ~tag_set r
  | Q.Or (l, r) -> match' ~ctx ~tag_set l || match' ~ctx ~tag_set r

let match_ ~ctx ~tag_set t = match' ~ctx ~tag_set t.q

let rec of_ast =
  let module T = Terrat_tag_query_parser_value in
  function
  | T.In_dir glob_str ->
      let glob = Path_glob.Glob.parse (Printf.sprintf "<**/%s/**>" (escape_glob glob_str)) in
      Q.Dir_glob (glob_str, Path_glob.Glob.eval glob)
  | T.Tag q when CCString.starts_with ~prefix:dir_in_prefix q ->
      let glob_str = CCString.drop dir_in_prefix_len q in
      let glob = Path_glob.Glob.parse (Printf.sprintf "<**/%s/**>" (escape_glob glob_str)) in
      Q.Dir_glob (glob_str, Path_glob.Glob.eval glob)
  | T.Tag tag -> Q.Tag tag
  | T.And (l, r) | T.Implicit_and (l, r) -> Q.And (of_ast l, of_ast r)
  | T.Or (l, r) -> Q.Or (of_ast l, of_ast r)
  | T.Not e -> Q.Not (of_ast e)

let rec has_implicit_and =
  let module T = Terrat_tag_query_parser_value in
  function
  | T.Implicit_and _ -> true
  | T.And (l, r) | T.Or (l, r) -> has_implicit_and l || has_implicit_and r
  | T.Not e -> has_implicit_and e
  | T.Tag _ | T.In_dir _ -> false

(* Collect the operands of a query that is nothing but directory selectors joined
   by [or]s and implicit [and]s, in the order they were written.  A dirspace is in
   exactly one directory, so every implicit [and] in such a query is a dead
   conjunct and the user certainly meant [or] throughout.  Any other shape,
   [dir:foo workspace:prod] for instance, is a sensible [and] and must not be
   rewritten, so it yields [None]. *)
let rec dir_selectors =
  let module T = Terrat_tag_query_parser_value in
  function
  | T.Implicit_and (l, r) | T.Or (l, r) -> (
      match (dir_selectors l, dir_selectors r) with
      | Some l, Some r -> Some (l @ r)
      | Some _, None | None, Some _ | None, None -> None)
  | T.Tag tag
    when CCString.starts_with ~prefix:dir_prefix tag
         || CCString.starts_with ~prefix:dir_in_prefix tag -> Some [ tag ]
  | T.In_dir glob_str -> Some [ glob_str ^ " in dir" ]
  | T.Tag _ | T.And _ | T.Not _ -> None

(* The order the selectors were written in is the order to offer them back in, so
   this keeps the first of any repeat rather than sorting. *)
let uniq_in_order =
  CCFun.(
    CCList.fold_left (fun acc s -> if CCList.mem ~eq:CCString.equal s acc then acc else s :: acc) []
    %> CCList.rev)

let warning_of_ast ast =
  match has_implicit_and ast with
  | false -> None
  | true ->
      let suggestion =
        match CCOption.map uniq_in_order (dir_selectors ast) with
        | Some (_ :: _ :: _ as selectors) -> Some (CCString.concat " or " selectors)
        | Some ([] | [ _ ]) | None -> None
      in
      Some (Implicit_and { suggestion })

let of_string s =
  match Terrat_tag_query_ast.of_string s with
  | Ok (Some ast) -> Ok { q = of_ast ast; s; warning = warning_of_ast ast }
  | Ok None -> Ok { q = Q.Any; s; warning = None }
  | Error _ as err -> err

let to_string t = t.s
let warning t = t.warning
let any = { q = Q.Any; s = ""; warning = None }
