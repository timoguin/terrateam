(* The rule that decides which dirspaces run now, and whether the evaluator
   starts another round on its own.

   These are the two halves of a tree of runs (RFD 2305).  A run used to be a
   fixed list of layers, so a dirspace waited for every dirspace of the layer in
   front of it whether it depended on it or not.  Now the run that remains is
   put into layers again on every evaluation, so a dirspace waits for the
   dirspaces it depends on and for nothing else.

   The fixtures here are the system-test fixtures, built in OCaml so the whole
   sequence can be walked without a repository, a database or a VCS. *)

module Ws = Terrat_vcs_event_evaluator2.Work_set
module Tcm = Terrat_change_match3
module R = Terrat_base_repo_config_v1

let ctx = R.Ctx.make ~dest_branch:"main" ~branch:"test" ()
let tag_query s = CCResult.get_exn (Terrat_tag_query.of_string s)
let depends_on_q s = { R.Depends_on.tag_query = tag_query s; prune_on_no_change = false }

let dir ?tag ?depends_on () =
  R.Dirs.Dir.make
    ~workspaces:
      (Sln_map.String.of_list
         [
           ( "default",
             R.Dirs.Workspace.make
               ~tags:(CCOption.map_or ~default:[] (fun t -> [ t ]) tag)
               ~when_modified:
                 (R.When_modified.make ?depends_on:(CCOption.map depends_on_q depends_on) ())
               () );
         ])
    ()

let stack ?rules tq = R.Stacks.Stack.make ~type_:(R.Stacks.Type_.Stack (tag_query tq)) ?rules ()

let synthesize ~file_list ~dirs ?stacks () =
  let repo_config =
    CCResult.get_exn
      (R.derive
         ~ctx
         ~index:R.Index.empty
         ~file_list
         (R.of_view
            (R.View.make
               ~dirs:(Sln_map.String.of_list dirs)
               ?stacks:
                 (CCOption.map
                    (fun names -> R.Stacks.make ~names:(Sln_map.String.of_list names) ())
                    stacks)
               ())))
  in
  CCResult.get_exn (Tcm.synthesize_config ~index:R.Index.empty repo_config)

let changed filenames =
  CCList.map (fun filename -> Terrat_change.Diff.Change { filename }) filenames

let dirspace dir = { Terrat_dirspace.dir; workspace = "default" }

let dirs_of dirspace_configs =
  CCList.sort CCString.compare
  @@ CCList.map
       (fun {
              Tcm.Dirspace_config.dirspace = { Terrat_dirspace.dir; workspace = _ };
              file_pattern_matcher = _;
              lock_branch_target = _;
              stack_config = _;
              stack_name = _;
              stack_paths = _;
              tags = _;
              when_modified = _;
            }
          -> dir)
       dirspace_configs

let assert_dirs name expected actual =
  let show l = "[ " ^ CCString.concat "; " l ^ " ]" in
  Oth.Assert.true_
    ~fail_msg:(name ^ ": expected " ^ show expected ^ ", got " ^ show actual)
    (CCList.equal CCString.equal expected actual)

(* One evaluation.  [applied] is everything the database would call applied by
   now, which includes a dirspace whose last plan found no changes. *)
let work_set ~config ~all_matches ~op ?(tq = Terrat_tag_query.any) applied =
  Ws.make
    ~config
    ~op
    ~tag_query:tq
    ~applied:(Terrat_data.Dirspace_set.of_list (CCList.map dirspace applied))
    ~dir_exists:(fun _ -> true)
    ~all_matches

let remaining_after ~config ~all_matches applied =
  (work_set ~config ~all_matches ~op:Ws.Op.Layer_plan applied).Ws.all_unapplied_matches

(* ------------------------------------------------------------------ *)
(* core/stacks/0027: two environments, one stack each, apply_after on prod. *)

let two_environments ?(stacks = true) () =
  let env_dirs =
    [
      ("dev/networking", dir ~tag:"dev" ());
      ("dev/database", dir ~tag:"dev" ~depends_on:"dir:dev/networking" ());
      ("dev/app", dir ~tag:"dev" ~depends_on:"dir:dev/database" ());
      ("prod/networking", dir ~tag:"prod" ());
      ("prod/database", dir ~tag:"prod" ~depends_on:"dir:prod/networking" ());
      ("prod/app", dir ~tag:"prod" ~depends_on:"dir:prod/database" ());
    ]
  in
  synthesize
    ~file_list:(CCList.map (fun (d, _) -> d ^ "/main.tf") env_dirs)
    ~dirs:env_dirs
    ?stacks:
      (if stacks then
         Some
           [
             ("dev", stack "dev");
             ("prod", stack ~rules:(R.Stacks.Rules.make ~apply_after:[ "dev" ] ()) "prod");
           ]
       else None)
    ()

let networking_diff = changed [ "dev/networking/main.tf"; "prod/networking/main.tf" ]

(* The seven steps of core/stacks/0027, in order.  Before RFD 2305 the run
   stopped at step 3: prod/networking sat in the first layer, apply_after held
   it back, and dev/database sat in a later layer that could never be
   reached. *)
let test_two_environments_with_stacks =
  Oth.test ~name:"0027: the run walks both environments to the end" (fun _ ->
      let config = two_environments () in
      let all_matches = Tcm.match_diff_list config networking_diff in
      let plan applied =
        dirs_of (work_set ~config ~all_matches ~op:Ws.Op.Layer_plan applied).Ws.working_set_matches
      in
      let apply applied =
        dirs_of (work_set ~config ~all_matches ~op:Ws.Op.Apply applied).Ws.working_set_matches
      in
      (* 1. The two networking directories plan together: apply_after adds no
            plan edge, so the environments interleave. *)
      assert_dirs "autoplan" [ "dev/networking"; "prod/networking" ] (plan []);
      (* 2. apply_after holds prod/networking back, so the apply takes
            dev/networking on its own. *)
      assert_dirs "first apply" [ "dev/networking" ] (apply []);
      (* 3. dev/database is free, because its only dependency is applied.
            prod/networking is still free to plan. *)
      assert_dirs "second plan" [ "dev/database"; "prod/networking" ] (plan [ "dev/networking" ]);
      assert_dirs "second apply" [ "dev/database" ] (apply [ "dev/networking" ]);
      (* 4. dev/app. *)
      assert_dirs
        "third plan"
        [ "dev/app"; "prod/networking" ]
        (plan [ "dev/networking"; "dev/database" ]);
      assert_dirs "third apply" [ "dev/app" ] (apply [ "dev/networking"; "dev/database" ]);
      (* 5. No dev dirspace is left unapplied, so prod/networking is free. *)
      let dev = [ "dev/networking"; "dev/database"; "dev/app" ] in
      assert_dirs "fourth apply" [ "prod/networking" ] (apply dev);
      (* 6, 7. The rest of prod, one round each. *)
      assert_dirs "fifth plan" [ "prod/database" ] (plan ("prod/networking" :: dev));
      assert_dirs "fifth apply" [ "prod/database" ] (apply ("prod/networking" :: dev));
      let prod_db = "prod/database" :: "prod/networking" :: dev in
      assert_dirs "sixth plan" [ "prod/app" ] (plan prod_db);
      assert_dirs "sixth apply" [ "prod/app" ] (apply prod_db);
      (* Nothing left. *)
      Oth.Assert.true_
        ~fail_msg:"the run is over"
        (CCList.is_empty (remaining_after ~config ~all_matches ("prod/app" :: prod_db)));
      ())

(* The same six directories with no stacks.  A user can walk one branch of the
   tree to its end before starting the other one, which the fixed layers made
   impossible: after dev/networking applied, the first layer held only
   prod/networking, and dev/database could not plan until it applied. *)
let test_two_environments_without_stacks =
  Oth.test ~name:"no stacks: one branch can be walked to the end" (fun _ ->
      let config = two_environments ~stacks:false () in
      let all_matches = Tcm.match_diff_list config networking_diff in
      let plan applied =
        dirs_of (work_set ~config ~all_matches ~op:Ws.Op.Layer_plan applied).Ws.working_set_matches
      in
      let apply ~tq applied =
        dirs_of (work_set ~config ~all_matches ~op:Ws.Op.Apply ~tq applied).Ws.working_set_matches
      in
      assert_dirs "autoplan" [ "dev/networking"; "prod/networking" ] (plan []);
      (* The user picks one of the two with a tag query.  Nothing holds the
         other one back. *)
      assert_dirs
        "apply dev/networking"
        [ "dev/networking" ]
        (apply ~tq:(tag_query "dir:dev/networking") []);
      assert_dirs
        "dev/database joins prod/networking"
        [ "dev/database"; "prod/networking" ]
        (plan [ "dev/networking" ]);
      assert_dirs
        "apply dev/database"
        [ "dev/database" ]
        (apply ~tq:(tag_query "dir:dev/database") [ "dev/networking" ]);
      assert_dirs
        "dev/app joins prod/networking"
        [ "dev/app"; "prod/networking" ]
        (plan [ "dev/networking"; "dev/database" ]);
      let dev = [ "dev/networking"; "dev/database"; "dev/app" ] in
      (* With dev finished, only prod/networking is ready.  Nothing ordered the
         two environments, so the user was free to interleave them. *)
      assert_dirs "only prod/networking is left ready" [ "prod/networking" ] (plan dev);
      ())

(* ------------------------------------------------------------------ *)
(* next_round_ready. *)

let ready ~config ~all_matches ~applied ~just_ran =
  Ws.next_round_ready
    ~config
    ~all_unapplied_matches:(remaining_after ~config ~all_matches applied)
    ~just_ran:(CCList.map dirspace just_ran)

(* core/layered_runs/0008: base, then database1 and database2 together, then
   webservice.  An apply of one of the two databases frees nobody -- webservice
   still waits for the other one -- so no further plan may be set going.  This is
   the negative assertion the fixture makes. *)
let layered_run_0008 () =
  let ds =
    [
      ("base", dir ());
      ("database1", dir ~depends_on:"dir:base" ());
      ("database2", dir ~depends_on:"dir:base" ());
      ("webservice", dir ~depends_on:"dir:database1 or dir:database2" ());
    ]
  in
  synthesize ~file_list:(CCList.map (fun (d, _) -> d ^ "/main.tf") ds) ~dirs:ds ()

(* core/stacks/0004: one layer, ordered only by apply_after.  The apply of tf2
   frees tf1 to APPLY, but tf1 was already planned with tf2 in the first place,
   so there is nothing to plan and no round to start. *)
let stacks_0004 () =
  synthesize
    ~file_list:[ "tf1/main.tf"; "tf2/main.tf" ]
    ~dirs:[ ("tf1", dir ~tag:"tf1" ()); ("tf2", dir ~tag:"tf2" ()) ]
    ~stacks:
      [
        ("stack1", stack ~rules:(R.Stacks.Rules.make ~apply_after:[ "stack2" ] ()) "dir:tf1");
        ("stack2", stack "dir:tf2");
      ]
    ()

let test_next_round_ready =
  Oth.test ~name:"next_round_ready: a round starts only when the first layer gains" (fun _ ->
      let config = two_environments () in
      let all_matches = Tcm.match_diff_list config networking_diff in
      let ready_here = ready ~config ~all_matches in
      (* A plan leaves everything it planned in the run, so nothing is gained
         and the run does not plan the same layer again. *)
      Oth.Assert.true_
        ~fail_msg:"a plan does not start a round"
        (not (ready_here ~applied:[] ~just_ran:[ "dev/networking"; "prod/networking" ]));
      (* An apply that frees a dependent does start one. *)
      Oth.Assert.true_
        ~fail_msg:"applying dev/networking frees dev/database"
        (ready_here ~applied:[ "dev/networking" ] ~just_ran:[ "dev/networking" ]);
      (* An apply that frees nobody does not.  prod/networking was ready before
         dev/app applied and is still ready; nothing new joined it. *)
      let dev = [ "dev/networking"; "dev/database"; "dev/app" ] in
      Oth.Assert.true_
        ~fail_msg:"applying dev/app frees nobody"
        (not (ready_here ~applied:dev ~just_ran:[ "dev/app" ]));
      Oth.Assert.true_
        ~fail_msg:"applying prod/networking frees prod/database"
        (ready_here ~applied:("prod/networking" :: dev) ~just_ran:[ "prod/networking" ]);
      (* core/layered_runs/0008. *)
      let config = layered_run_0008 () in
      let all_matches = Tcm.match_diff_list config (changed [ "base/main.tf" ]) in
      Oth.Assert.true_
        ~fail_msg:"0008: a partial apply of a layer frees nobody"
        (not
           (ready ~config ~all_matches ~applied:[ "base"; "database1" ] ~just_ran:[ "database1" ]));
      (* core/stacks/0004. *)
      let config = stacks_0004 () in
      let all_matches = Tcm.match_diff_list config (changed [ "tf1/main.tf"; "tf2/main.tf" ]) in
      Oth.Assert.true_
        ~fail_msg:"0004: apply_after frees an apply, not a plan"
        (not (ready ~config ~all_matches ~applied:[ "tf2" ] ~just_ran:[ "tf2" ]));
      ())

(* An explicit tag query may name a dirspace that is already applied -- a
   dirspace whose last plan found no changes counts as applied -- so a scoped
   re-plan has to reach it.  A layer selection would come up empty and tell the
   user everything was applied. *)
let test_explicit_plan_reaches_an_applied_dirspace =
  Oth.test ~name:"an explicit query can re-plan an applied dirspace" (fun _ ->
      let config = two_environments () in
      let all_matches = Tcm.match_diff_list config networking_diff in
      let selected =
        dirs_of
          (work_set
             ~config
             ~all_matches
             ~op:Ws.Op.Explicit_plan
             ~tq:(tag_query "dir:dev/networking")
             [ "dev/networking" ])
            .Ws.working_set_matches
      in
      assert_dirs "explicit plan" [ "dev/networking" ] selected;
      (* The same query under a layer selection selects nothing, because
         dev/networking has left the run. *)
      assert_dirs
        "layer plan"
        []
        (dirs_of
           (work_set
              ~config
              ~all_matches
              ~op:Ws.Op.Layer_plan
              ~tq:(tag_query "dir:dev/networking")
              [ "dev/networking" ])
             .Ws.working_set_matches);
      ())

(* A directory that has been deleted cannot run, and it must not hold its
   dependents back either. *)
let test_a_deleted_directory_does_not_block =
  Oth.test ~name:"a dirspace whose directory is gone holds nothing back" (fun _ ->
      let config = two_environments () in
      let all_matches = Tcm.match_diff_list config networking_diff in
      let { Ws.working_set_matches; all_unapplied_matches = _; working_layer = _ } =
        Ws.make
          ~config
          ~op:Ws.Op.Layer_plan
          ~tag_query:Terrat_tag_query.any
          ~applied:Terrat_data.Dirspace_set.empty
          ~dir_exists:(fun d -> not (CCString.equal "dev/networking" d))
          ~all_matches
      in
      assert_dirs
        "dev/database takes the place of the deleted dev/networking"
        [ "dev/database"; "prod/networking" ]
        (dirs_of working_set_matches);
      ())

let test =
  Oth.parallel
    [
      test_two_environments_with_stacks;
      test_two_environments_without_stacks;
      test_next_round_ready;
      test_explicit_plan_reaches_an_applied_dirspace;
      test_a_deleted_directory_does_not_block;
    ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
