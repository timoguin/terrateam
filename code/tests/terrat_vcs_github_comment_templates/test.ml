module Tmpl = Terrat_vcs_github_comment_templates.Tmpl

let render tmpl kv =
  match Minijinja.render_template tmpl kv with
  | Ok body -> body
  | Error err -> failwith err

(* The same payload shape the provider builds for the [no matching dirspaces]
   messages, see [Terrat_vcs_provider2.Msg.no_matching_dirspaces_kv]. *)
let kv ~tag_query ~implicit_and ~suggestion =
  `Assoc
    [
      ("tag_query", `String tag_query);
      ("implicit_and", `Bool implicit_and);
      ( "suggestion",
        match suggestion with
        | Some suggestion -> `String suggestion
        | None -> `Null );
    ]

let test_apply_no_warning =
  Oth.test ~name:"Apply no warning" (fun _ ->
      let body =
        render
          Tmpl.apply_no_matching_dirspaces
          (kv ~tag_query:"dir:foo" ~implicit_and:false ~suggestion:None)
      in
      Oth.Assert.str_contains
        ~haystack:body
        ~needle:"There are no matching changes that are pending apply.";
      Oth.Assert.str_doesnt_contain ~haystack:body ~needle:"Did you mean")

let test_apply_warning_with_suggestion =
  Oth.test ~name:"Apply warning with suggestion" (fun _ ->
      let body =
        render
          Tmpl.apply_no_matching_dirspaces
          (kv
             ~tag_query:"dir:foo dir:bar"
             ~implicit_and:true
             ~suggestion:(Some "dir:foo or dir:bar"))
      in
      Oth.Assert.str_contains_all
        ~haystack:body
        ~needles:
          [
            "There are no matching changes that are pending apply.";
            "[!WARNING]";
            "Did you mean `or`?";
            "terrateam apply dir:foo or dir:bar";
          ])

let test_apply_warning_without_suggestion =
  Oth.test ~name:"Apply warning without suggestion" (fun _ ->
      let body =
        render
          Tmpl.apply_no_matching_dirspaces
          (kv ~tag_query:"dir:foo workspace:prod" ~implicit_and:true ~suggestion:None)
      in
      Oth.Assert.str_contains_all
        ~haystack:body
        ~needles:[ "Did you mean `or`?"; "`dir:foo workspace:prod`" ];
      (* Without a rewrite the only command offered is the unfiltered one. *)
      Oth.Assert.str_doesnt_contain ~haystack:body ~needle:"terrateam apply dir:")

let test_plan_no_warning =
  Oth.test ~name:"Plan no warning" (fun _ ->
      let body =
        render
          Tmpl.plan_no_matching_dirspaces
          (kv ~tag_query:"dir:foo" ~implicit_and:false ~suggestion:None)
      in
      Oth.Assert.str_contains ~haystack:body ~needle:"There are no matching changes to plan.";
      Oth.Assert.str_doesnt_contain ~haystack:body ~needle:"Did you mean")

let test_plan_warning_with_suggestion =
  Oth.test ~name:"Plan warning with suggestion" (fun _ ->
      let body =
        render
          Tmpl.plan_no_matching_dirspaces
          (kv
             ~tag_query:"dir:foo dir:bar"
             ~implicit_and:true
             ~suggestion:(Some "dir:foo or dir:bar"))
      in
      Oth.Assert.str_contains_all
        ~haystack:body
        ~needles:
          [
            "There are no matching changes to plan.";
            "Did you mean `or`?";
            "terrateam plan dir:foo or dir:bar";
          ])

let test_tag_query_dropped_dirspaces =
  Oth.test ~name:"Tag query dropped dirspaces" (fun _ ->
      let body =
        render
          Tmpl.tag_query_dropped_dirspaces
          (`Assoc
             [
               ("command", `String "terrateam apply");
               ("suggestion", `String "dir:a or dir:b or dir:c");
               ( "dirspaces",
                 `List
                   [
                     `Assoc [ ("dir", `String "b"); ("workspace", `String "default") ];
                     `Assoc [ ("dir", `String "c"); ("workspace", `String "default") ];
                   ] );
             ])
      in
      Oth.Assert.str_contains_all
        ~haystack:body
        ~needles:
          [
            "Some Directories Were Left Out";
            "| `b` | `default` |";
            "| `c` | `default` |";
            "terrateam apply dir:a or dir:b or dir:c";
          ])

let test_matches_in_later_layer =
  Oth.test ~name:"Matches in later layer" (fun _ ->
      let body =
        render
          Tmpl.matches_in_later_layer
          (`Assoc
             [
               ( "dirspaces",
                 `List
                   [
                     `Assoc [ ("dir", `String "tql/app"); ("workspace", `String "default") ];
                     `Assoc [ ("dir", `String "tql/web"); ("workspace", `String "prod") ];
                   ] );
             ])
      in
      Oth.Assert.str_contains_all
        ~haystack:body
        ~needles:
          [
            "Waiting On An Earlier Layer";
            "| `tql/app` | `default` |";
            "| `tql/web` | `prod` |";
            "terrateam plan";
          ])

(* Every [Operation_failed] template renders the request id, because it is the
   only handle support has on the failure. *)
let test_operation_failed_branch_not_found =
  Oth.test ~name:"Operation failed branch not found" (fun _ ->
      let body =
        render
          Tmpl.operation_failed_branch_not_found
          (`Assoc [ ("request_id", `String "req-123"); ("branch", `String "release/v2") ])
      in
      Oth.Assert.str_contains_all ~haystack:body ~needles:[ "req-123"; "release/v2" ])

let test_operation_failed_compute_aborted =
  Oth.test ~name:"Operation failed compute aborted" (fun _ ->
      let body =
        render
          Tmpl.operation_failed_compute_aborted
          (`Assoc [ ("request_id", `String "req-123"); ("num_aborts", `Int 11) ])
      in
      Oth.Assert.str_contains_all ~haystack:body ~needles:[ "req-123"; "11" ])

let test_operation_failed_db_err =
  Oth.test ~name:"Operation failed db err" (fun _ ->
      let body =
        render Tmpl.operation_failed_db_err (`Assoc [ ("request_id", `String "req-123") ])
      in
      Oth.Assert.str_contains ~haystack:body ~needle:"req-123")

let test_operation_failed_internal_err =
  Oth.test ~name:"Operation failed internal err" (fun _ ->
      let body =
        render
          Tmpl.operation_failed_internal_err
          (`Assoc [ ("request_id", `String "req-123"); ("tag", `String "EXPECTED_REPO_TREE") ])
      in
      Oth.Assert.str_contains_all ~haystack:body ~needles:[ "req-123"; "EXPECTED_REPO_TREE" ])

let test_operation_failed_vcs_api_err =
  Oth.test ~name:"Operation failed vcs api err" (fun _ ->
      let body =
        render
          Tmpl.operation_failed_vcs_api_err
          (`Assoc
             [ ("request_id", `String "req-123"); ("operation", `String "CREATE_COMMIT_CHECKS") ])
      in
      Oth.Assert.str_contains_all ~haystack:body ~needles:[ "req-123"; "CREATE_COMMIT_CHECKS" ])

let test_operation_failed_work_manifest_start_err =
  Oth.test ~name:"Operation failed work manifest start err" (fun _ ->
      let body =
        render
          Tmpl.operation_failed_work_manifest_start_err
          (`Assoc [ ("request_id", `String "req-123") ])
      in
      Oth.Assert.str_contains ~haystack:body ~needle:"req-123")

(* The bad-glob comment.  [pattern] is the glob as written in the repository
   configuration and [glob] is what it expands to; the template says so only
   when the two differ, because repeating an unsubstituted glob back at the
   reader tells them nothing. *)
let bad_glob_kv ~location ~pattern ~glob ~error =
  `Assoc
    [
      ("location", `String location);
      ("pattern", `String pattern);
      ("glob", `String glob);
      ("error", `String error);
    ]

let test_bad_glob_err_unsubstituted =
  Oth.test ~name:"Bad glob, nothing substituted" (fun _ ->
      let body =
        render
          Tmpl.repo_config_err_bad_glob_err
          (bad_glob_kv
             ~location:{|dirs."**"|}
             ~pattern:"**"
             ~glob:"**"
             ~error:"Ambiguous ** pattern not allowed unless surrounded by one or more slashes")
      in
      Oth.Assert.str_contains_all
        ~haystack:body
        ~needles:[ "Could not parse the glob `**`"; {|`dirs."**"`|}; "Ambiguous ** pattern" ];
      Oth.Assert.str_doesnt_contain ~haystack:body ~needle:"which expands to";
      ())

let test_bad_glob_err_substituted =
  Oth.test ~name:"Bad glob, ${DIR} substituted" (fun _ ->
      let body =
        render
          Tmpl.repo_config_err_bad_glob_err
          (bad_glob_kv
             ~location:{|dirs."a+b".workspaces."default".when_modified.file_patterns|}
             ~pattern:"${DIR}/*.tf"
             ~glob:"a+b/*.tf"
             ~error:"Unexpected character '+' in glob pattern")
      in
      Oth.Assert.str_contains_all
        ~haystack:body
        ~needles:
          [
            "Could not parse the glob `a+b/*.tf`";
            {|`dirs."a+b".workspaces."default".when_modified.file_patterns`|};
            "written as `${DIR}/*.tf`";
            "which expands to `a+b/*.tf`";
            "Unexpected character '+' in glob pattern";
          ];
      ())

(* The payload [Msg.Missing_plans] builds, one row per reason.  Snabela errors on
   a key a template asks for and the map does not carry, so the provider emits
   all three flags on every row and this pins that. *)
let missing_plans_kv rows =
  Snabela.Kv.(
    Map.of_list
      [
        ( "dirspaces",
          list
            (CCList.map
               (fun (dir, workspace, never_planned, invalidated, invalidated_by, last_run_failed) ->
                 Map.of_list
                   [
                     ("dir", string dir);
                     ("workspace", string workspace);
                     ("never_planned", bool never_planned);
                     ("last_run_failed", bool last_run_failed);
                     ("invalidated", bool invalidated);
                     ("invalidated_by", int invalidated_by);
                   ])
               rows) );
        ( "any_invalidated",
          bool (CCList.exists (fun (_, _, _, invalidated, _, _) -> invalidated) rows) );
      ])

let render_missing_plans rows =
  match Snabela.apply Tmpl.missing_plans (missing_plans_kv rows) with
  | Ok body -> body
  | Error (#Snabela.err as err) -> failwith (Snabela.show_err err)

let test_missing_plans_never_planned =
  Oth.test ~name:"Missing plans: never planned" (fun _ ->
      let body = render_missing_plans [ ("foo", "default", true, false, 0, false) ] in
      Oth.Assert.str_contains ~haystack:body ~needle:"Never planned on this ref";
      Oth.Assert.str_doesnt_contain ~haystack:body ~needle:"superseded")

let test_missing_plans_invalidated =
  Oth.test ~name:"Missing plans: invalidated names the pull request" (fun _ ->
      let body = render_missing_plans [ ("foo", "default", false, true, 849, false) ] in
      Oth.Assert.str_contains ~haystack:body ~needle:"Plan superseded by #849";
      Oth.Assert.str_doesnt_contain ~haystack:body ~needle:"Never planned")

let test_missing_plans_last_run_failed =
  Oth.test ~name:"Missing plans: last run failed" (fun _ ->
      let body = render_missing_plans [ ("foo", "default", false, false, 0, true) ] in
      Oth.Assert.str_contains ~haystack:body ~needle:"The last run for this directory failed";
      Oth.Assert.str_doesnt_contain ~haystack:body ~needle:"superseded")

let test_missing_plans_mixed_reasons =
  Oth.test ~name:"Missing plans: every reason renders in one table" (fun _ ->
      let body =
        render_missing_plans
          [
            ("a", "default", true, false, 0, false);
            ("b", "default", false, true, 12, false);
            ("c", "default", false, false, 0, true);
          ]
      in
      Oth.Assert.str_contains ~haystack:body ~needle:"Never planned on this ref";
      Oth.Assert.str_contains ~haystack:body ~needle:"Plan superseded by #12";
      Oth.Assert.str_contains ~haystack:body ~needle:"The last run for this directory failed")

let test =
  Oth.parallel
    [
      test_operation_failed_branch_not_found;
      test_operation_failed_compute_aborted;
      test_operation_failed_db_err;
      test_operation_failed_internal_err;
      test_operation_failed_vcs_api_err;
      test_operation_failed_work_manifest_start_err;
      test_matches_in_later_layer;
      test_tag_query_dropped_dirspaces;
      test_apply_no_warning;
      test_apply_warning_with_suggestion;
      test_apply_warning_without_suggestion;
      test_plan_no_warning;
      test_plan_warning_with_suggestion;
      test_bad_glob_err_unsubstituted;
      test_bad_glob_err_substituted;
      test_missing_plans_never_planned;
      test_missing_plans_invalidated;
      test_missing_plans_last_run_failed;
      test_missing_plans_mixed_reasons;
    ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
