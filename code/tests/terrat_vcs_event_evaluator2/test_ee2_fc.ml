(* Tests for the rerun-aware result applicative,
   [Terrat_vcs_event_evaluator2_fc].

   A [`Rerun] is not a failure. It is a task saying it committed something and
   that the evaluation has to be driven again, because a guard of its own will
   answer differently on the second pass. The applicative in
   [Abbs_future_combinators] keeps the error of its LEFT operand and throws the
   right one away, so a destination-branch tree that finished while the branch
   half of the evaluation was still suspended lost its [`Rerun], the driver
   never re-drove, and the work manifest stayed in [running] for ever.

   The property these tests hold down: no combination of errors can drop a
   [`Rerun], wherever it sits. *)

module Oth_abb = Oth_abb.Make (Abb)
module Ee2_fc = Terrat_vcs_event_evaluator2.Ee2_fc

(* [merge_err] is row-polymorphic in every constructor but [`Rerun], so three
   stand-ins are enough: a rerun, the suspension it is paired with in the
   evaluation that went wrong, and a true failure. *)
type err =
  [ `Rerun of string list
  | `Suspend_eval of string
  | `Boom
  ]

let pp_err fmt = function
  | `Rerun ids -> Format.fprintf fmt "`Rerun [%s]" (CCString.concat "; " ids)
  | `Suspend_eval name -> Format.fprintf fmt "`Suspend_eval %s" name
  | `Boom -> Format.fprintf fmt "`Boom"

let pp_result pp_ok fmt = function
  | Ok v -> Format.fprintf fmt "Ok %a" pp_ok v
  | Error err -> Format.fprintf fmt "Error %a" pp_err err

let assert_err ~expected ~actual = Oth_abb.Assert.eq ~eq:( = ) ~pp:pp_err expected actual

let assert_result ~expected ~actual =
  Oth_abb.Assert.eq ~eq:( = ) ~pp:(pp_result (fun fmt _ -> Format.fprintf fmt "_")) expected actual

(* --- merge_err: the ranking, on its own --------------------------------- *)

let merge_test ~name ~(a : err) ~(b : err) ~(expected : err) =
  Oth_abb.test ~name (fun () ->
      assert_err ~expected ~actual:(Ee2_fc.merge_err a b);
      Abb.Future.return ())

let test_rerun_beats_suspend_on_the_right =
  merge_test
    ~name:"merge: a rerun on the right beats a suspended left"
    ~a:(`Suspend_eval "branch_dirspaces")
    ~b:(`Rerun [ "repo_tree:1:abc" ])
    ~expected:(`Rerun [ "repo_tree:1:abc" ])

let test_rerun_beats_suspend_on_the_left =
  merge_test
    ~name:"merge: a rerun on the left beats a suspended right"
    ~a:(`Rerun [ "repo_tree:1:abc" ])
    ~b:(`Suspend_eval "dest_branch_dirspaces")
    ~expected:(`Rerun [ "repo_tree:1:abc" ])

(* A true error must not win. Winning would roll the transaction back, throw
   away the write the rerun was protecting, and leave the work manifest that
   named it in [running]. The user still hears about the failure: this pass
   says nothing, and the next pass reports it on its own. *)
let test_rerun_beats_a_true_error =
  merge_test
    ~name:"merge: a rerun beats a true error, on either side"
    ~a:`Boom
    ~b:(`Rerun [ "repo_tree:1:abc" ])
    ~expected:(`Rerun [ "repo_tree:1:abc" ])

let test_a_true_error_does_not_beat_a_rerun =
  merge_test
    ~name:"merge: a true error on the right does not beat a rerun"
    ~a:(`Rerun [ "repo_tree:1:abc" ])
    ~b:`Boom
    ~expected:(`Rerun [ "repo_tree:1:abc" ])

(* An evaluation runs its tasks concurrently, so more than one can commit in a
   single pass. A name that does not reach the driver is a name whose task
   writes again on the pass after this one. Deduplicated because the build
   system keeps a task's error against its key, so one task that two paths
   fetch in the same pass hands the same name back twice. *)
let test_two_reruns_join =
  merge_test
    ~name:"merge: two reruns join, deduplicated and sorted"
    ~a:(`Rerun [ "repo_tree:1:bbb"; "repo_tree:1:aaa" ])
    ~b:(`Rerun [ "repo_tree:1:ccc"; "repo_tree:1:aaa" ])
    ~expected:(`Rerun [ "repo_tree:1:aaa"; "repo_tree:1:bbb"; "repo_tree:1:ccc" ])

(* Everything that is not a rerun keeps the left, which is what
   [Abbs_future_combinators] does and what the rest of the evaluator relies on.
   This module changes the rerun case and nothing else. *)
let test_without_a_rerun_the_left_wins =
  merge_test
    ~name:"merge: without a rerun the left error is kept"
    ~a:(`Suspend_eval "branch_dirspaces")
    ~b:(`Suspend_eval "dest_branch_dirspaces")
    ~expected:(`Suspend_eval "branch_dirspaces")

(* --- all2 and the operator ----------------------------------------------- *)

(* The production case: [can_run_plan] combines a suspended [branch_dirspaces]
   with a [dest_branch_dirspaces] that has just stored the destination tree.
   [Abbs_future_combinators.Result.all2] answers [`Suspend_eval] here. *)
let test_all2_keeps_the_rerun =
  Oth_abb.test ~name:"all2: a suspended left does not swallow a rerunning right" (fun () ->
      let open Abb.Future.Infix_monad in
      Ee2_fc.all2
        (Abb.Future.return (Error (`Suspend_eval "branch_dirspaces")))
        (Abb.Future.return (Error (`Rerun [ "repo_tree:1:abc" ])))
      >>= fun actual ->
      assert_result ~expected:(Error (`Rerun [ "repo_tree:1:abc" ])) ~actual;
      Abb.Future.return ())

let test_all2_success =
  Oth_abb.test ~name:"all2: two successes give the pair" (fun () ->
      let open Abb.Future.Infix_monad in
      Ee2_fc.all2 (Abb.Future.return (Ok 1)) (Abb.Future.return (Ok 2))
      >>= fun actual ->
      Oth_abb.Assert.eq
        ~eq:( = )
        ~pp:(pp_result (fun fmt (a, b) -> Format.fprintf fmt "(%d, %d)" a b))
        (Ok (1, 2))
        actual;
      Abb.Future.return ())

(* The tuple helpers are built on the operator, so a rerun in the middle of one
   has to survive too. *)
let test_all3_keeps_a_rerun_in_the_middle =
  Oth_abb.test ~name:"all3: a rerun in the middle survives" (fun () ->
      let open Abb.Future.Infix_monad in
      Ee2_fc.all3
        (Abb.Future.return (Error (`Suspend_eval "one")))
        (Abb.Future.return (Error (`Rerun [ "repo_tree:1:abc" ])))
        (Abb.Future.return (Error (`Suspend_eval "three")))
      >>= fun actual ->
      assert_result ~expected:(Error (`Rerun [ "repo_tree:1:abc" ])) ~actual;
      Abb.Future.return ())

(* A chain groups to the left, so the left operand carries the merged error as
   the chain grows. This is what lets the nine- and twelve-operand check chains
   in [Terrat_vcs_event_evaluator2_tasks_pr] stay chains rather than needing an
   [all9] and an [all12]. *)
let test_chain_keeps_a_rerun_in_the_last_position =
  Oth_abb.test ~name:"chain: a rerun in the last position of a chain survives" (fun () ->
      let open Abb.Future.Infix_monad in
      Ee2_fc.Infix_result_app.(
        (fun () () () () -> ())
        <$> Abb.Future.return (Error (`Suspend_eval "one"))
        <*> Abb.Future.return (Ok ())
        <*> Abb.Future.return (Error (`Suspend_eval "three"))
        <*> Abb.Future.return (Error (`Rerun [ "repo_tree:1:abc" ])))
      >>= fun actual ->
      assert_result ~expected:(Error (`Rerun [ "repo_tree:1:abc" ])) ~actual;
      Abb.Future.return ())

(* An [Error] on one side must not abort or skip the other: that is the
   behaviour [Abbs_future_combinators] documents, and it is the only reason the
   right side's [`Rerun] is there to be merged at all.  Both sides yield to the
   scheduler so that "it ran" means it ran during the evaluation, not when the
   future was built. *)
let test_both_sides_run_when_the_left_errors =
  Oth_abb.test ~name:"all2: the right side still runs when the left errors" (fun () ->
      let open Abb.Future.Infix_monad in
      let right_ran = ref false in
      Ee2_fc.all2
        (Abb.Sys.sleep 0.0 >>= fun () -> Abb.Future.return (Error (`Suspend_eval "left")))
        (Abb.Sys.sleep 0.01
        >>= fun () ->
        right_ran := true;
        Abb.Future.return (Ok ()))
      >>= fun actual ->
      Oth_abb.Assert.true_ "the right side of all2 never ran" !right_ran;
      assert_result ~expected:(Error (`Suspend_eval "left")) ~actual;
      Abb.Future.return ())

let test =
  Oth_abb.parallel
    [
      test_rerun_beats_suspend_on_the_right;
      test_rerun_beats_suspend_on_the_left;
      test_rerun_beats_a_true_error;
      test_a_true_error_does_not_beat_a_rerun;
      test_two_reruns_join;
      test_without_a_rerun_the_left_wins;
      test_all2_keeps_the_rerun;
      test_all2_success;
      test_all3_keeps_a_rerun_in_the_middle;
      test_chain_keeps_a_rerun_in_the_last_position;
      test_both_sides_run_when_the_left_errors;
    ]

let () =
  Random.self_init ();
  Oth_abb.run
    ~file:__FILE__
    ~setup:(fun () -> Abbs_future_combinators.return_ok ())
    ~teardown:(fun () -> Abb.Future.return ())
    (fun () -> test)
