module Tmpl = Terrat_vcs_gitlab_comment_templates.Tmpl

let render tmpl kv =
  match Minijinja.render_template tmpl kv with
  | Ok body -> body
  | Error err -> failwith err

(* Every [<details>] the apply comment opens must close, and no [</details>] may
   run ahead of its open.  #1975: the per-dirspace [<details>] opened under
   [compact_dirspaces] but closed under [compact_view], so an apply of more than
   five dirspaces emitted one open per dirspace and a single close, and the
   reader saw every dirspace nested inside the previous one. *)
let details_balance body =
  let len = CCString.length body in
  let rec go idx depth min_depth =
    if idx >= len then (depth, min_depth)
    else if idx + 10 <= len && CCString.equal "</details>" (CCString.sub body idx 10) then
      go (idx + 10) (depth - 1) (CCInt.min min_depth (depth - 1))
    else if idx + 8 <= len && CCString.equal "<details" (CCString.sub body idx 8) then
      go (idx + 8) (depth + 1) min_depth
    else go (idx + 1) depth min_depth
  in
  go 0 0 0

let apply_complete2_kv ~compact_view ~num_dirspaces =
  `Assoc
    [
      ("overall_success", `Bool true);
      ("summary", `Bool true);
      ("account_status", `String "active");
      ("trial_end_days", `Int 0);
      ("is_layered_run", `Bool false);
      ("num_more_layers", `Int 0);
      ("denied_dirspaces", `List []);
      ("pre_hooks", `List []);
      ("post_hooks", `List []);
      ("gates", `List []);
      ("compact_view", `Bool compact_view);
      (* The publisher's own rule, see [Terrat_vcs_gitlab_comment_publishers]. *)
      ("compact_dirspaces", `Bool (num_dirspaces > 5));
      ( "dirspaces",
        `List
          (CCList.map
             (fun idx ->
               `Assoc
                 [
                   ("dir", `String (Printf.sprintf "dir-%d" idx));
                   ("workspace", `String "default");
                   ("success", `Bool true);
                   ( "steps",
                     `List
                       [
                         `Assoc
                           [
                             ("name", `String "apply");
                             ("text", `String "Apply complete!");
                             ("show_output", `Bool true);
                             ("success", `Bool true);
                             ("raw", `Bool false);
                             ("text_decorator", `String "");
                           ];
                       ] );
                   ("has_changes", `Bool true);
                   ("run_url", `Null);
                 ])
             (CCList.range 1 num_dirspaces)) );
    ]

let test_apply_complete2_details ~name ~compact_view ~num_dirspaces =
  Oth.test ~tags:[ "comment_details" ] ~name (fun _ ->
      let body = render Tmpl.apply_complete2 (apply_complete2_kv ~compact_view ~num_dirspaces) in
      let depth, min_depth = details_balance body in
      Oth.Assert.true_ (Printf.sprintf "%d <details> left open" depth) (depth = 0);
      Oth.Assert.true_
        (Printf.sprintf "</details> without an open, depth reached %d" min_depth)
        (min_depth >= 0);
      ())

let test_apply_complete2_details_many_dirspaces =
  test_apply_complete2_details
    ~name:"Apply complete: 10 dirspaces, normal view"
    ~compact_view:false
    ~num_dirspaces:10

let test_apply_complete2_details_few_dirspaces =
  test_apply_complete2_details
    ~name:"Apply complete: 3 dirspaces, normal view"
    ~compact_view:false
    ~num_dirspaces:3

let test_apply_complete2_details_few_dirspaces_compact_view =
  test_apply_complete2_details
    ~name:"Apply complete: 3 dirspaces, compact view"
    ~compact_view:true
    ~num_dirspaces:3

(* A call the VCS never answered is a separate comment from a call that failed,
   so that the reader is told GitLab is unresponsive rather than that Stategraph
   broke. *)
let test_operation_failed_vcs_api_timeout_err =
  Oth.test ~name:"Operation failed vcs api timeout err" (fun _ ->
      let body =
        render
          Tmpl.operation_failed_vcs_api_timeout_err
          (`Assoc [ ("request_id", `String "req-123"); ("operation", `String "FETCH_PULL_REQUEST") ])
      in
      Oth.Assert.str_contains_all
        ~haystack:body
        ~needles:[ "req-123"; "FETCH_PULL_REQUEST"; "GitLab"; "timed out" ];
      Oth.Assert.str_doesnt_contain ~haystack:body ~needle:"UNKNOWN")

(* #2038: a plan whose dirspaces all came back with no changes must not tell the
   reader to apply, and a layered run must say the next layer follows on its
   own. *)
let plan_complete2_kv ~changes ~is_layered_run ~num_more_layers =
  `Assoc
    [
      ("overall_success", `Bool true);
      ("summary", `Bool true);
      ("account_status", `String "active");
      ("trial_end_days", `Int 0);
      ("is_layered_run", `Bool is_layered_run);
      ("num_more_layers", `Int num_more_layers);
      ("denied_dirspaces", `List []);
      ("pre_hooks", `List []);
      ("post_hooks", `List []);
      ("gates", `List []);
      ("compact_view", `Bool false);
      ("compact_dirspaces", `Bool false);
      ( "dirspaces",
        `List
          (CCList.mapi
             (fun idx has_changes ->
               `Assoc
                 [
                   ("dir", `String (Printf.sprintf "dir-%d" idx));
                   ("workspace", `String "default");
                   ("success", `Bool true);
                   ( "steps",
                     `List
                       [
                         `Assoc
                           [
                             ("name", `String "tf/plan");
                             ("text", `String "No changes.");
                             ("show_output", `Bool true);
                             ("success", `Bool true);
                             ("raw", `Bool false);
                             ("text_decorator", `String "diff");
                           ];
                       ] );
                   ("has_changes", `Bool has_changes);
                   ("run_url", `Null);
                   ("applied", `Bool false);
                 ])
             changes) );
    ]

let apply_footer = "To apply all these changes, comment:"
let no_changes_layer = "There are no changes in this layer."
let next_layer = "The next layer will now be planned."

let test_plan_complete2_no_changes_more_layers =
  Oth.test ~tags:[ "plan_complete" ] ~name:"Plan complete: no changes, more layers" (fun _ ->
      let body =
        render
          Tmpl.plan_complete2
          (plan_complete2_kv ~changes:[ false ] ~is_layered_run:true ~num_more_layers:3)
      in
      Oth.Assert.str_contains_all ~haystack:body ~needles:[ no_changes_layer; next_layer ];
      Oth.Assert.str_doesnt_contain ~haystack:body ~needle:apply_footer)

(* [num_more_layers] counts the layer just planned, so one remaining layer means
   this is the last one. *)
let test_plan_complete2_no_changes_last_layer =
  Oth.test ~tags:[ "plan_complete" ] ~name:"Plan complete: no changes, last layer" (fun _ ->
      let body =
        render
          Tmpl.plan_complete2
          (plan_complete2_kv ~changes:[ false ] ~is_layered_run:true ~num_more_layers:1)
      in
      Oth.Assert.str_contains ~haystack:body ~needle:no_changes_layer;
      Oth.Assert.str_contains ~haystack:body ~needle:"with 1 layer remaining to apply";
      Oth.Assert.str_doesnt_contain ~haystack:body ~needle:next_layer;
      Oth.Assert.str_doesnt_contain ~haystack:body ~needle:apply_footer)

let test_plan_complete2_no_changes_not_layered =
  Oth.test ~tags:[ "plan_complete" ] ~name:"Plan complete: no changes, not layered" (fun _ ->
      let body =
        render
          Tmpl.plan_complete2
          (plan_complete2_kv ~changes:[ false ] ~is_layered_run:false ~num_more_layers:0)
      in
      Oth.Assert.str_contains ~haystack:body ~needle:"There are no changes.";
      Oth.Assert.str_doesnt_contain ~haystack:body ~needle:"in this layer";
      Oth.Assert.str_doesnt_contain ~haystack:body ~needle:apply_footer)

let test_plan_complete2_changes_keep_apply =
  Oth.test ~tags:[ "plan_complete" ] ~name:"Plan complete: changes keep the apply footer" (fun _ ->
      let body =
        render
          Tmpl.plan_complete2
          (plan_complete2_kv ~changes:[ true ] ~is_layered_run:true ~num_more_layers:3)
      in
      Oth.Assert.str_contains ~haystack:body ~needle:apply_footer;
      Oth.Assert.str_doesnt_contain ~haystack:body ~needle:"There are no changes")

(* One dirspace with changes is enough to make the apply instruction correct. *)
let test_plan_complete2_mixed_keeps_apply =
  Oth.test
    ~tags:[ "plan_complete" ]
    ~name:"Plan complete: mixed dirspaces keep the apply footer"
    (fun _ ->
      let body =
        render
          Tmpl.plan_complete2
          (plan_complete2_kv ~changes:[ true; false ] ~is_layered_run:true ~num_more_layers:3)
      in
      Oth.Assert.str_contains ~haystack:body ~needle:apply_footer;
      Oth.Assert.str_doesnt_contain ~haystack:body ~needle:no_changes_layer)

let test =
  Oth.parallel
    [
      test_plan_complete2_no_changes_more_layers;
      test_plan_complete2_no_changes_last_layer;
      test_plan_complete2_no_changes_not_layered;
      test_plan_complete2_changes_keep_apply;
      test_plan_complete2_mixed_keeps_apply;
      test_operation_failed_vcs_api_timeout_err;
      test_apply_complete2_details_many_dirspaces;
      test_apply_complete2_details_few_dirspaces;
      test_apply_complete2_details_few_dirspaces_compact_view;
    ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
