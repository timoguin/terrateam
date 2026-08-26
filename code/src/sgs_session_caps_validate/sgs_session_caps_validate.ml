type err =
  | Invalid_pattern_err of string
  | Pattern_too_long_err of string
  | Too_many_patterns_err of int

let max_patterns_per_list = 64
let ( let* ) = CCResult.( >>= )

(* [first_error f l] applies [f] to each element, returning the first [Error] (so the message names
   the exact offending entry) or [Ok ()] when all pass. *)
let rec first_error f = function
  | [] -> Ok ()
  | x :: xs -> (
      match f x with
      | Ok () -> first_error f xs
      | Error _ as e -> e)

let check_pattern s =
  if CCString.length s > Sg_caps_match.max_pattern_length then Error (Pattern_too_long_err s)
  else if not (Sg_caps_match.is_valid_pattern s) then Error (Invalid_pattern_err s)
  else Ok ()

let check_list l =
  let n = CCList.length l in
  if n > max_patterns_per_list then Error (Too_many_patterns_err n) else first_error check_pattern l

let check_list_opt = function
  | None -> Ok ()
  | Some l -> check_list l

(* A [null] state value means "all resources" and carries no patterns. *)
let check_states_opt = function
  | None -> Ok ()
  | Some s ->
      first_error
        check_list_opt
        (Sln_map.String.fold (fun _ v acc -> v :: acc) (Sgs_session_caps_states.additional s) [])

let check_commit { Sgs_session_caps_commit.states; subgraph; tenants } =
  let* () = check_states_opt states in
  let* () = check_states_opt subgraph in
  check_list_opt tenants

let check_preview { Sgs_session_caps_preview.states; subgraph; tenants } =
  let* () = check_states_opt states in
  let* () = check_states_opt subgraph in
  check_list_opt tenants

let check_admin { Sgs_session_caps_admin.tenants } = check_list_opt tenants
let check_sudo { Sgs_session_caps_sudo.users } = check_list users
let check_users_manage { Sgs_session_caps_users_manage.tenants } = check_list_opt tenants

let check_opt f = function
  | None -> Ok ()
  | Some x -> f x

let validate caps =
  let open Sgs_session_caps_capabilities in
  let* () = check_opt check_admin caps.admin in
  let* () = check_opt check_commit caps.commit in
  let* () = check_opt check_preview caps.preview in
  let* () = check_opt check_sudo caps.sudo in
  check_opt check_users_manage caps.users_manage

(* The interface pins [pp_err]/[show_err] via [@@deriving show] in the .mli; here we provide a custom
   human-readable implementation (suitable for an [error-response] [data] field) matching it. *)
let pp_err fmt = function
  | Invalid_pattern_err s ->
      Format.fprintf
        fmt
        "invalid capability pattern %S: only a single trailing '*' wildcard is allowed"
        s
  | Pattern_too_long_err s ->
      Format.fprintf
        fmt
        "capability pattern exceeds %d characters: %S"
        Sg_caps_match.max_pattern_length
        s
  | Too_many_patterns_err n ->
      Format.fprintf
        fmt
        "capability list has %d patterns, exceeding the maximum of %d"
        n
        max_patterns_per_list

let show_err err = Format.asprintf "%a" pp_err err
