(* Self-hosted checks for [Oth.Assert.List.str_mem].

   As in [tags_test.ml], checks go through [check] rather than [assert], because the release profile
   compiles with -noassert. *)

let check msg b = if not b then failwith ("check failed: " ^ msg)

let fails f =
  match f () with
  | () -> false
  | exception _ -> true

let () =
  check "a member passes" (not (fails (fun () -> Oth.Assert.List.str_mem "b" [ "a"; "b"; "c" ])));
  check "an absent string fails" (fails (fun () -> Oth.Assert.List.str_mem "d" [ "a"; "b"; "c" ]));
  check "the empty list fails" (fails (fun () -> Oth.Assert.List.str_mem "a" []));
  check
    "a message does not change the answer"
    (fails (fun () -> Oth.Assert.List.str_mem ~fail_msg:"why" "d" [ "a" ]))
