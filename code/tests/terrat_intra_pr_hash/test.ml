(* Tests for the rules which decide, on a push to a pull request, which dirspaces run again and
   which dirspaces keep the result of an earlier run.

   Every test names its dirspaces by directory only, and every dirspace uses the "default"
   workspace, thus an assertion is a comparison of two lists of directory names. *)

module Ipr = Terrat_intra_pr_hash

(* The head sha of the pull request now.  A run at this sha is always good, because a tree cannot
   differ from itself. *)
let head = "head"
let ds dir = { Terrat_dirspace.dir; workspace = "default" }
let dirs_of = CCList.map (fun { Terrat_dirspace.dir; workspace = _ } -> dir)
let dirspace_set dirs = Terrat_data.Dirspace_set.of_list (CCList.map ds dirs)
let layers ls = CCList.map (fun l -> CCList.map ds l) ls
let run ~sha ~created_at = { Ipr.Run.sha; created_at }

let plan ?(has_changes = true) ~sha ~created_at () =
  { Ipr.Plan.run = run ~sha ~created_at; has_changes }

let state ?last_plan ?last_apply dir =
  { Ipr.Dirspace_state.dirspace = ds dir; last_plan; last_apply }

(* [changes] is a list of (sha, the directories which changed between that sha and the head).  A
   sha which is absent has no change. *)
let changed_dirspaces changes sha =
  changes |> CCList.assoc_opt ~eq:CCString.equal sha |> CCOption.get_or ~default:[] |> dirspace_set

let select
    ?(changes = [])
    ?(force = [])
    ?(superseded = [])
    ?(last_run_failed = [])
    ?(ls = [])
    states =
  Ipr.select
    ~changed_dirspaces:(changed_dirspaces changes)
    ~force:(dirspace_set force)
    ~superseded:(dirspace_set superseded)
    ~last_run_failed:(dirspace_set last_run_failed)
    ~layers:(layers ls)
    states

let assert_to_run ~expected { Ipr.Selection.to_run; applied = _ } =
  Oth.Assert.Eq.string_list ~expected ~actual:(dirs_of to_run)

let assert_applied ~expected { Ipr.Selection.to_run = _; applied } =
  Oth.Assert.Eq.string_list ~expected ~actual:(dirs_of applied)

(* -- Autoplan filtering -- *)

let test_no_plan_runs =
  Oth.test ~name:"autoplan: a dirspace with no plan runs" (fun _ ->
      let selection = select [ state "ds_one" ] in
      assert_to_run ~expected:[ "ds_one" ] selection;
      assert_applied ~expected:[] selection;
      ())

(* A failed plan is not a successful plan, thus [last_plan] holds the run before the failure.  That
   run is at the sha from before the change which the user pushed, thus its files are different now
   and the dirspace runs. *)
let test_failed_plan_runs =
  Oth.test ~name:"autoplan: a dirspace whose last plan failed runs" (fun _ ->
      let selection =
        select
          ~changes:[ ("old", [ "ds_one" ]) ]
          [ state "ds_one" ~last_plan:(plan ~sha:"old" ~created_at:"2026-09-11T10:00:00Z" ()) ]
      in
      assert_to_run ~expected:[ "ds_one" ] selection;
      ())

let test_unchanged_plan_does_not_run =
  Oth.test ~name:"autoplan: a plan with no changed file does not run again" (fun _ ->
      let selection =
        select
          ~changes:[ ("old", [ "ds_two" ]) ]
          [ state "ds_one" ~last_plan:(plan ~sha:"old" ~created_at:"2026-09-11T10:00:00Z" ()) ]
      in
      assert_to_run ~expected:[] selection;
      ())

let test_changed_plan_runs =
  Oth.test ~name:"autoplan: a plan with a changed file runs again" (fun _ ->
      let selection =
        select
          ~changes:[ ("old", [ "ds_one"; "ds_two" ]) ]
          [
            state "ds_one" ~last_plan:(plan ~sha:"old" ~created_at:"2026-09-11T10:00:00Z" ());
            state "ds_two" ~last_plan:(plan ~sha:"old" ~created_at:"2026-09-11T10:00:00Z" ());
            state "ds_three" ~last_plan:(plan ~sha:"old" ~created_at:"2026-09-11T10:00:00Z" ());
          ]
      in
      assert_to_run ~expected:[ "ds_one"; "ds_two" ] selection;
      ())

(* The caller must do nothing with an empty selection, and must not make a work manifest which
   holds no dirspace. *)
let test_everything_filtered_is_empty =
  Oth.test ~name:"autoplan: every dirspace filtered out gives an empty selection" (fun _ ->
      let selection =
        select
          [
            state "ds_one" ~last_plan:(plan ~sha:head ~created_at:"2026-09-11T10:00:00Z" ());
            state "ds_two" ~last_plan:(plan ~sha:head ~created_at:"2026-09-11T10:00:00Z" ());
          ]
      in
      assert_to_run ~expected:[] selection;
      ())

(* -- Applied state -- *)

let test_apply_survives_an_unrelated_push =
  Oth.test ~name:"applied: an apply survives a push which does not touch its files" (fun _ ->
      let selection =
        select
          ~changes:[ ("sha_a", [ "ds_two" ]) ]
          [
            state
              "ds_one"
              ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:00:00Z" ())
              ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T10:05:00Z");
          ]
      in
      assert_applied ~expected:[ "ds_one" ] selection;
      assert_to_run ~expected:[] selection;
      ())

let test_apply_lost_when_a_file_changed =
  Oth.test ~name:"applied: an apply is lost when one of its files changed" (fun _ ->
      let selection =
        select
          ~changes:[ ("sha_a", [ "ds_one" ]) ]
          [
            state
              "ds_one"
              ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:00:00Z" ())
              ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T10:05:00Z");
          ]
      in
      assert_applied ~expected:[] selection;
      assert_to_run ~expected:[ "ds_one" ] selection;
      ())

(* A plan which found no changes has nothing to apply, thus it counts as applied.  This is the
   [plans_with_no_changes] union of select_dirspace_applies_for_context.sql. *)
let test_clean_plan_counts_as_applied =
  Oth.test ~name:"applied: a plan with no changes counts as applied and survives a push" (fun _ ->
      let selection =
        select
          ~changes:[ ("sha_a", [ "ds_two" ]) ]
          [
            state
              "ds_one"
              ~last_plan:
                (plan ~has_changes:false ~sha:"sha_a" ~created_at:"2026-09-11T10:00:00Z" ());
          ]
      in
      assert_applied ~expected:[ "ds_one" ] selection;
      assert_to_run ~expected:[] selection;
      ())

(* -- Layers -- *)

let three_layers = [ [ "l_one" ]; [ "l_two" ]; [ "l_three" ] ]

let test_working_layer_stays_at_the_third_layer =
  Oth.test ~name:"layers: two applied layers stay applied when their files did not change" (fun _ ->
      let selection =
        select
          ~ls:three_layers
          [
            state
              "l_one"
              ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:00:00Z" ())
              ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T10:01:00Z");
            state
              "l_two"
              ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:02:00Z" ())
              ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T10:03:00Z");
            state "l_three";
          ]
      in
      assert_applied ~expected:[ "l_one"; "l_two" ] selection;
      assert_to_run ~expected:[ "l_three" ] selection;
      ())

let test_force_in_the_first_layer_rewinds =
  Oth.test
    ~name:"layers: a force match in the first layer makes that layer the working layer"
    (fun _ ->
      let selection =
        select
          ~ls:three_layers
          ~force:[ "l_one" ]
          [
            state
              "l_one"
              ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:00:00Z" ())
              ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T10:01:00Z");
            state
              "l_two"
              ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:02:00Z" ())
              ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T10:03:00Z");
            state
              "l_three"
              ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:04:00Z" ())
              ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T10:05:00Z");
          ]
      in
      assert_to_run ~expected:[ "l_one" ] selection;
      assert_applied ~expected:[] selection;
      ())

(* After the forced run of the first layer lands, its work manifest is the most recent one.  The
   applies of the later layers are older than it, thus they no longer count. *)
let test_a_later_first_layer_run_invalidates_the_layers_after_it =
  Oth.test
    ~name:"layers: a run in the first layer after the later layers invalidates them"
    (fun _ ->
      let selection =
        select
          ~ls:three_layers
          [
            state "l_one" ~last_plan:(plan ~sha:head ~created_at:"2026-09-11T11:00:00Z" ());
            state
              "l_two"
              ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:02:00Z" ())
              ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T10:03:00Z");
            state
              "l_three"
              ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:04:00Z" ())
              ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T10:05:00Z");
          ]
      in
      assert_applied ~expected:[] selection;
      ())

(* The state of 0008 at the moment the user comments [terrateam apply], after the forced plan of
   [l_one] landed.  The force lives only in the evaluation which carries the tag query, thus
   [force] is empty here and the plan of [l_one] is what must keep the rewind alive.  Without it
   the apply of [l_one] never runs, and the apply reaches [l_two] instead. *)
let test_a_forced_plan_outlives_the_force =
  Oth.test ~name:"layers: a plan made after an apply makes that dirspace unapplied" (fun _ ->
      let selection =
        select
          ~ls:three_layers
          ~changes:[ ("sha_a", [ "l_three" ]) ]
          [
            state
              "l_one"
              ~last_plan:(plan ~sha:head ~created_at:"2026-09-11T11:14:00Z" ())
              ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T11:10:00Z");
            state
              "l_two"
              ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T11:10:00Z" ())
              ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T11:12:00Z");
            state "l_three" ~last_plan:(plan ~sha:head ~created_at:"2026-09-11T11:13:00Z" ());
          ]
      in
      (* [l_one] holds a good plan, thus it needs no new one -- it needs to be applied. *)
      assert_applied ~expected:[] selection;
      assert_to_run ~expected:[ "l_three"; "l_two" ] selection;
      ())

(* The step after {!test_a_forced_plan_outlives_the_force}: [l_one] is applied, thus its apply is
   now the most recent run of the first layer and the layers after it must plan again. *)
let test_the_layers_after_a_forced_apply_plan_again =
  Oth.test ~name:"layers: the layers after a forced apply lose their plans" (fun _ ->
      let selection =
        select
          ~ls:three_layers
          ~changes:[ ("sha_a", [ "l_three" ]) ]
          [
            state
              "l_one"
              ~last_plan:(plan ~sha:head ~created_at:"2026-09-11T11:14:00Z" ())
              ~last_apply:(run ~sha:head ~created_at:"2026-09-11T11:16:00Z");
            state
              "l_two"
              ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T11:10:00Z" ())
              ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T11:12:00Z");
            state "l_three" ~last_plan:(plan ~sha:head ~created_at:"2026-09-11T11:13:00Z" ());
          ]
      in
      assert_applied ~expected:[ "l_one" ] selection;
      assert_to_run ~expected:[ "l_three"; "l_two" ] selection;
      ())

let test_force_in_the_last_layer_keeps_the_earlier_layers =
  Oth.test
    ~name:"layers: a force match in the last layer does not invalidate the earlier layers"
    (fun _ ->
      let selection =
        select
          ~ls:three_layers
          ~force:[ "l_three" ]
          [
            state
              "l_one"
              ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:00:00Z" ())
              ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T10:01:00Z");
            state
              "l_two"
              ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:02:00Z" ())
              ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T10:03:00Z");
            state "l_three" ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:04:00Z" ());
          ]
      in
      assert_applied ~expected:[ "l_one"; "l_two" ] selection;
      assert_to_run ~expected:[ "l_three" ] selection;
      ())

let test_one_dirspace_of_a_layer_is_forced =
  Oth.test
    ~name:"layers: only the forced dirspace of a layer runs, and the later layers are lost"
    (fun _ ->
      let selection =
        select
          ~ls:[ [ "l_one" ]; [ "m_alpha"; "m_beta" ]; [ "l_three" ] ]
          ~force:[ "m_alpha" ]
          [
            state
              "l_one"
              ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:00:00Z" ())
              ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T10:01:00Z");
            state
              "m_alpha"
              ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:02:00Z" ())
              ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T10:03:00Z");
            state
              "m_beta"
              ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:02:00Z" ())
              ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T10:03:00Z");
            state
              "l_three"
              ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:04:00Z" ())
              ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T10:05:00Z");
          ]
      in
      assert_to_run ~expected:[ "m_alpha" ] selection;
      assert_applied ~expected:[ "l_one" ] selection;
      ())

(* -- Force path -- *)

let test_force_runs_an_unchanged_dirspace =
  Oth.test ~name:"force: a force match runs a dirspace whose files did not change" (fun _ ->
      let selection =
        select
          ~force:[ "ds_one" ]
          [
            state "ds_one" ~last_plan:(plan ~sha:head ~created_at:"2026-09-11T10:00:00Z" ());
            state "ds_two" ~last_plan:(plan ~sha:head ~created_at:"2026-09-11T10:00:00Z" ());
          ]
      in
      assert_to_run ~expected:[ "ds_one" ] selection;
      ())

(* Force planning reaches only the dirspaces which the pull request changes.  A dirspace which is
   not a candidate is not in [states], thus the force does nothing. *)
let test_force_outside_the_change_set_does_nothing =
  Oth.test ~name:"force: a force match outside the change set does not run" (fun _ ->
      let selection =
        select
          ~force:[ "ds_two" ]
          [ state "ds_one" ~last_plan:(plan ~sha:head ~created_at:"2026-09-11T10:00:00Z" ()) ]
      in
      assert_to_run ~expected:[] selection;
      ())

let test_empty_force_changes_nothing =
  Oth.test ~name:"force: an empty force set leaves the selection unchanged" (fun _ ->
      let states =
        [
          state
            "ds_one"
            ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:00:00Z" ())
            ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T10:01:00Z");
          state "ds_two";
        ]
      in
      let selection = select ~ls:[ [ "ds_one" ]; [ "ds_two" ] ] states in
      assert_to_run ~expected:[ "ds_two" ] selection;
      assert_applied ~expected:[ "ds_one" ] selection;
      ())

(* -- Ordering -- *)

(* Two runs can carry the same time, because the work manifest time has a resolution of one second
   and because a drift run plans every layer under one work manifest.  The result must not depend
   on the order of the input list. *)
let test_equal_times_are_deterministic =
  Oth.test
    ~name:"ordering: equal created_at values do not make the result depend on list order"
    (fun _ ->
      let states =
        [
          state
            "l_one"
            ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:00:00Z" ())
            ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T10:00:00Z");
          state
            "l_two"
            ~last_plan:(plan ~sha:"sha_a" ~created_at:"2026-09-11T10:00:00Z" ())
            ~last_apply:(run ~sha:"sha_a" ~created_at:"2026-09-11T10:00:00Z");
        ]
      in
      let ls = [ [ "l_one" ]; [ "l_two" ] ] in
      let forward = select ~ls states in
      let backward = select ~ls (CCList.rev states) in
      assert_applied ~expected:[ "l_one"; "l_two" ] forward;
      Oth.Assert.eq ~eq:Ipr.Selection.equal ~pp:Ipr.Selection.pp forward backward;
      ())

(* The shape the apply gate falls back to when the tree of the head is not in the database.  It
   hands [select] a [changed_dirspaces] which holds every dirspace, because a tree which is not
   there must mean "run it" and never "skip it".  Nothing may survive as applied, or a stale plan
   reaches an apply. *)
let test_everything_changed_runs_everything =
  Oth.test ~name:"guard: every dirspace changed runs everything and applies nothing" (fun _ ->
      let states =
        [
          state
            "l_one"
            ~last_plan:(plan ~sha:"old" ~created_at:"2026-09-11T10:00:00Z" ())
            ~last_apply:(run ~sha:"old" ~created_at:"2026-09-11T10:00:00Z");
          state
            "l_two"
            ~last_plan:(plan ~has_changes:false ~sha:"old" ~created_at:"2026-09-11T10:00:00Z" ());
          state "l_three";
        ]
      in
      let selection =
        Ipr.select
          ~changed_dirspaces:(fun _ -> dirspace_set [ "l_one"; "l_two"; "l_three" ])
          ~force:(dirspace_set [])
          ~superseded:(dirspace_set [])
          ~last_run_failed:(dirspace_set [])
          ~layers:(layers [ [ "l_one" ]; [ "l_two" ]; [ "l_three" ] ])
          states
      in
      assert_to_run ~expected:[ "l_one"; "l_three"; "l_two" ] selection;
      assert_applied ~expected:[] selection;
      ())

(* -- Superseded by another pull request -- *)

(* The files of the dirspace did not move, thus the file test alone keeps the plan.  Another pull
   request applied or merged the dirspace after that plan, thus the state the plan was built on is
   gone and the plan has to be made again. *)
let test_superseded_plan_runs =
  Oth.test ~name:"superseded: a plan which another pull request superseded runs again" (fun _ ->
      let selection =
        select
          ~superseded:[ "ds_one" ]
          [ state "ds_one" ~last_plan:(plan ~sha:"old" ~created_at:"2026-09-11T10:00:00Z" ()) ]
      in
      assert_to_run ~expected:[ "ds_one" ] selection;
      assert_applied ~expected:[] selection;
      ())

(* The apply of this pull request is gone the same way, thus the dirspace is unapplied and the
   evaluation gives it back to the layer which runs next. *)
let test_superseded_apply_is_not_applied =
  Oth.test
    ~name:"superseded: an apply which another pull request superseded does not count as applied"
    (fun _ ->
      let selection =
        select
          ~superseded:[ "ds_one" ]
          [
            state
              "ds_one"
              ~last_plan:(plan ~sha:"old" ~created_at:"2026-09-11T10:00:00Z" ())
              ~last_apply:(run ~sha:"old" ~created_at:"2026-09-11T11:00:00Z");
          ]
      in
      assert_to_run ~expected:[ "ds_one" ] selection;
      assert_applied ~expected:[] selection;
      ())

(* A plan which found no changes counts as applied.  That answer is about the state the plan read,
   thus the other pull request takes it away too. *)
let test_superseded_clean_plan_is_not_applied =
  Oth.test
    ~name:"superseded: a plan with no changes which another pull request superseded runs again"
    (fun _ ->
      let selection =
        select
          ~superseded:[ "ds_one" ]
          [
            state
              "ds_one"
              ~last_plan:(plan ~has_changes:false ~sha:"old" ~created_at:"2026-09-11T10:00:00Z" ());
          ]
      in
      assert_to_run ~expected:[ "ds_one" ] selection;
      assert_applied ~expected:[] selection;
      ())

(* The set names the dirspaces it names and no other one. *)
let test_superseded_reaches_only_its_dirspaces =
  Oth.test ~name:"superseded: a dirspace outside the set keeps its plan" (fun _ ->
      let selection =
        select
          ~superseded:[ "ds_one" ]
          [
            state "ds_one" ~last_plan:(plan ~sha:"old" ~created_at:"2026-09-11T10:00:00Z" ());
            state "ds_two" ~last_plan:(plan ~sha:"old" ~created_at:"2026-09-11T10:00:00Z" ());
          ]
      in
      assert_to_run ~expected:[ "ds_one" ] selection;
      ())

(* An empty set is the usual case and must change nothing. *)
let test_empty_superseded_changes_nothing =
  Oth.test ~name:"superseded: an empty set leaves the selection unchanged" (fun _ ->
      let states =
        [
          state
            "ds_one"
            ~last_plan:(plan ~sha:"old" ~created_at:"2026-09-11T10:00:00Z" ())
            ~last_apply:(run ~sha:"old" ~created_at:"2026-09-11T11:00:00Z");
        ]
      in
      Oth.Assert.eq
        ~eq:Ipr.Selection.equal
        ~pp:Ipr.Selection.pp
        (select states)
        (select ~superseded:[] states);
      ())

(* -- A run which failed -- *)

(* The files of the dirspace did not move since the plan which succeeded, thus the file test alone
   keeps that plan.  A newer run failed, and no row of [states] carries it, because the caller
   takes the successful runs only. *)
let test_failed_run_with_no_file_change_runs =
  Oth.test ~name:"failed: a newer failed run with no file change runs again" (fun _ ->
      let selection =
        select
          ~last_run_failed:[ "ds_one" ]
          [ state "ds_one" ~last_plan:(plan ~sha:"old" ~created_at:"2026-09-11T10:00:00Z" ()) ]
      in
      assert_to_run ~expected:[ "ds_one" ] selection;
      assert_applied ~expected:[] selection;
      ())

(* A plan which failed says nothing about an apply which succeeded.  Thus the dirspace stays
   applied, and the layers after it keep what they reached. *)
let test_failed_run_keeps_an_apply =
  Oth.test ~name:"failed: a failed run does not take away an apply which succeeded" (fun _ ->
      let selection =
        select
          ~last_run_failed:[ "l_one" ]
          ~ls:[ [ "l_one" ]; [ "l_two" ] ]
          [
            state
              "l_one"
              ~last_plan:(plan ~sha:"old" ~created_at:"2026-09-11T10:00:00Z" ())
              ~last_apply:(run ~sha:"old" ~created_at:"2026-09-11T11:00:00Z");
            state
              "l_two"
              ~last_plan:(plan ~sha:"old" ~created_at:"2026-09-11T12:00:00Z" ())
              ~last_apply:(run ~sha:"old" ~created_at:"2026-09-11T13:00:00Z");
          ]
      in
      assert_to_run ~expected:[] selection;
      assert_applied ~expected:[ "l_one"; "l_two" ] selection;
      ())

(* A plan which succeeded and which nobody applied is work which is still there.  A failed run
   after it must not turn that work into an applied dirspace. *)
let test_failed_run_does_not_apply_an_unapplied_plan =
  Oth.test
    ~name:"failed: a failed run after an unapplied plan does not make the dirspace applied"
    (fun _ ->
      let selection =
        select
          ~last_run_failed:[ "ds_one" ]
          [
            state
              "ds_one"
              ~last_plan:(plan ~sha:"old" ~created_at:"2026-09-11T12:00:00Z" ())
              ~last_apply:(run ~sha:"old" ~created_at:"2026-09-11T10:00:00Z");
          ]
      in
      assert_to_run ~expected:[ "ds_one" ] selection;
      assert_applied ~expected:[] selection;
      ())

(* The set names the dirspaces it names and no other one. *)
let test_empty_last_run_failed_changes_nothing =
  Oth.test ~name:"failed: an empty set leaves the selection unchanged" (fun _ ->
      let states =
        [ state "ds_one" ~last_plan:(plan ~sha:"old" ~created_at:"2026-09-11T10:00:00Z" ()) ]
      in
      Oth.Assert.eq
        ~eq:Ipr.Selection.equal
        ~pp:Ipr.Selection.pp
        (select states)
        (select ~last_run_failed:[] states);
      ())

(* -- The two lists are apart -- *)

(* An apply with no plan, which is what an unsafe-apply records.  The dirspace was applied, thus it
   has nothing left to do and it must not also be in the list of what runs. *)
let test_an_apply_with_no_plan_is_applied_only =
  Oth.test ~name:"lists: an apply with no plan is applied and does not run" (fun _ ->
      let selection =
        select [ state "ds_one" ~last_apply:(run ~sha:"old" ~created_at:"2026-09-11T10:00:00Z") ]
      in
      assert_to_run ~expected:[] selection;
      assert_applied ~expected:[ "ds_one" ] selection;
      ())

(* The same, over every case the other tests of this suite make: whatever the input, one dirspace
   is never in both lists. *)
let test_the_lists_never_overlap =
  Oth.test ~name:"lists: no dirspace is in both lists" (fun _ ->
      let states =
        [
          state "ds_one" ~last_apply:(run ~sha:"old" ~created_at:"2026-09-11T10:00:00Z");
          state
            "ds_two"
            ~last_plan:(plan ~has_changes:false ~sha:"old" ~created_at:"2026-09-11T10:00:00Z" ());
          state "ds_three" ~last_plan:(plan ~sha:"old" ~created_at:"2026-09-11T10:00:00Z" ());
          state "ds_four";
        ]
      in
      CCList.iter
        (fun (force, superseded, last_run_failed) ->
          let { Ipr.Selection.to_run; applied } =
            select ~force ~superseded ~last_run_failed states
          in
          let to_run = Terrat_data.Dirspace_set.of_list to_run in
          CCList.iter
            (fun dirspace -> Oth.Assert.not_true (Terrat_data.Dirspace_set.mem dirspace to_run))
            applied)
        [
          ([], [], []);
          ([ "ds_one" ], [], []);
          ([], [ "ds_one" ], []);
          ([], [], [ "ds_one" ]);
          ([], [], [ "ds_two" ]);
          ([ "ds_two" ], [ "ds_three" ], [ "ds_one" ]);
        ];
      ())

let test =
  Oth.parallel
    [
      test_no_plan_runs;
      test_failed_plan_runs;
      test_unchanged_plan_does_not_run;
      test_changed_plan_runs;
      test_everything_filtered_is_empty;
      test_apply_survives_an_unrelated_push;
      test_apply_lost_when_a_file_changed;
      test_clean_plan_counts_as_applied;
      test_working_layer_stays_at_the_third_layer;
      test_force_in_the_first_layer_rewinds;
      test_a_later_first_layer_run_invalidates_the_layers_after_it;
      test_a_forced_plan_outlives_the_force;
      test_the_layers_after_a_forced_apply_plan_again;
      test_force_in_the_last_layer_keeps_the_earlier_layers;
      test_one_dirspace_of_a_layer_is_forced;
      test_force_runs_an_unchanged_dirspace;
      test_force_outside_the_change_set_does_nothing;
      test_empty_force_changes_nothing;
      test_equal_times_are_deterministic;
      test_everything_changed_runs_everything;
      test_superseded_plan_runs;
      test_superseded_apply_is_not_applied;
      test_superseded_clean_plan_is_not_applied;
      test_superseded_reaches_only_its_dirspaces;
      test_empty_superseded_changes_nothing;
      test_failed_run_with_no_file_change_runs;
      test_failed_run_keeps_an_apply;
      test_failed_run_does_not_apply_an_unapplied_plan;
      test_empty_last_run_failed_changes_nothing;
      test_an_apply_with_no_plan_is_applied_only;
      test_the_lists_never_overlap;
    ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
