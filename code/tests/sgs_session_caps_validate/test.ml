let commit tenants = Some (Sgs_session_caps_commit.make ~tenants:(Some tenants) ())
let sudo users = Some (Sgs_session_caps_sudo.make ~users)
let admin tenants = Some (Sgs_session_caps_admin.make ~tenants:(Some tenants) ())

(* [validate] returns [Ok ()]; the [pp] passed to [Oth.Assert.error_pp] only ever prints the (unit)
   success value, so a placeholder suffices. *)
let assert_validate_err expected c =
  let err =
    Oth.Assert.error_pp
      ~pp:(fun fmt () -> Format.pp_print_string fmt "ok")
      (Sgs_session_caps_validate.validate c)
  in
  Oth.Assert.eq ~eq:( = ) ~pp:Sgs_session_caps_validate.pp_err expected err

let valid =
  Oth.test ~name:"valid" (fun _ ->
      let c =
        Sgs_session_caps_capabilities.make
          ~commit:(commit [ "a.*"; "aws_*"; "foo.bar" ])
          ~sudo:(sudo [ "x*" ])
          ()
      in
      Oth.Assert.ok_pp ~pp:Sgs_session_caps_validate.pp_err (Sgs_session_caps_validate.validate c))

let rejects_mid_star =
  Oth.test ~name:"rejects_mid_star" (fun _ ->
      let c = Sgs_session_caps_capabilities.make ~commit:(commit [ "a.*"; "a*b" ]) () in
      assert_validate_err (Sgs_session_caps_validate.Invalid_pattern_err "a*b") c)

let rejects_too_long =
  Oth.test ~name:"rejects_too_long" (fun _ ->
      let long = CCString.make (Sg_caps_match.max_pattern_length + 1) 'a' in
      let c = Sgs_session_caps_capabilities.make ~sudo:(sudo [ long ]) () in
      assert_validate_err (Sgs_session_caps_validate.Pattern_too_long_err long) c)

(* Admin carries a tenant allow-list like every other scoped capability, so its patterns are
   validated at the input boundary too. *)
let rejects_admin_mid_star =
  Oth.test ~name:"rejects_admin_mid_star" (fun _ ->
      let c = Sgs_session_caps_capabilities.make ~admin:(admin [ "t1"; "t*1" ]) () in
      assert_validate_err (Sgs_session_caps_validate.Invalid_pattern_err "t*1") c)

let rejects_too_many =
  Oth.test ~name:"rejects_too_many" (fun _ ->
      let n = Sgs_session_caps_validate.max_patterns_per_list + 1 in
      let pats = CCList.init n (fun i -> "p" ^ string_of_int i) in
      let c = Sgs_session_caps_capabilities.make ~commit:(commit pats) () in
      assert_validate_err (Sgs_session_caps_validate.Too_many_patterns_err n) c)

let test =
  Oth.parallel
    [ valid; rejects_mid_star; rejects_admin_mid_star; rejects_too_long; rejects_too_many ]

let () = Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
