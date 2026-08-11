(* Round-trip tests for the new Engine.Stategraph variant in v1 base config.
   Drives through the public of_version_1_json / to_version_1 surface so we
   exercise the new pattern-match arms in of_version_1_engine and
   to_version_1_engine end to end. *)

module V1 = Terrat_base_repo_config_v1
module Repo = Terrat_repo_config
module Sg_schema = Terrat_repo_config.Engine_stategraph

let pp_engine = function
  | V1.Engine.Stategraph _ -> "Stategraph"
  | V1.Engine.Cdktf _ -> "Cdktf"
  | V1.Engine.Custom _ -> "Custom"
  | V1.Engine.Fly _ -> "Fly"
  | V1.Engine.Opentofu _ -> "Opentofu"
  | V1.Engine.Other _ -> "Other"
  | V1.Engine.Pulumi -> "Pulumi"
  | V1.Engine.Terraform _ -> "Terraform"
  | V1.Engine.Terragrunt _ -> "Terragrunt"

let test_of_version_1_json_minimal =
  Oth.test ~name:"of_version_1_json: stategraph engine (no version)" (fun _ ->
      let json = `Assoc [ ("engine", `Assoc [ ("name", `String "stategraph") ]) ] in
      match V1.of_version_1_json json with
      | Ok cfg -> (
          match V1.engine cfg with
          | V1.Engine.Stategraph { V1.Engine.Stategraph.version = None; _ } -> ()
          | other ->
              failwith
                (Printf.sprintf
                   "Expected Engine.Stategraph with version=None, got %s"
                   (pp_engine other)))
      | Error _ -> failwith "of_version_1_json failed on minimal stategraph engine config")

let test_of_version_1_json_with_version =
  Oth.test ~name:"of_version_1_json: stategraph engine (with version)" (fun _ ->
      let json =
        `Assoc
          [ ("engine", `Assoc [ ("name", `String "stategraph"); ("version", `String "1.2.1") ]) ]
      in
      match V1.of_version_1_json json with
      | Ok cfg -> (
          match V1.engine cfg with
          | V1.Engine.Stategraph { V1.Engine.Stategraph.version = Some "1.2.1"; _ } -> ()
          | other ->
              failwith
                (Printf.sprintf
                   "Expected Engine.Stategraph with version=Some 1.2.1, got %s"
                   (pp_engine other)))
      | Error _ -> failwith "of_version_1_json failed on stategraph engine with version")

let test_to_version_1_round_trip =
  Oth.test ~name:"to_version_1: stategraph engine round-trips through Version_1" (fun _ ->
      let json =
        `Assoc
          [ ("engine", `Assoc [ ("name", `String "stategraph"); ("version", `String "1.2.1") ]) ]
      in
      match V1.of_version_1_json json with
      | Ok cfg -> (
          let v1 = V1.to_version_1 cfg in
          match v1.Repo.Version_1.engine with
          | Some
              (Repo.Engine.Engine_stategraph
                 { Sg_schema.name = `Stategraph; version = Some "1.2.1"; _ }) -> ()
          | _ -> failwith "Round-trip to Version_1 did not produce Engine_stategraph")
      | Error _ -> failwith "of_version_1_json failed in round-trip setup")

(* Tests for the global [lock_policy] key.  A workflow entry that does not set
   [lock_policy] inherits the global value, an entry that sets it overrides the
   global value, and the global value round-trips through Version_1. *)

let pp_lock_policy = function
  | V1.Workflows.Entry.Lock_policy.Apply -> "apply"
  | V1.Workflows.Entry.Lock_policy.Merge -> "merge"
  | V1.Workflows.Entry.Lock_policy.None -> "none"
  | V1.Workflows.Entry.Lock_policy.Strict -> "strict"

let config_of_json json =
  match V1.of_version_1_json json with
  | Ok cfg -> cfg
  | Error _ -> failwith "of_version_1_json failed"

let assert_lock_policy expected actual =
  if not (V1.Workflows.Entry.Lock_policy.equal expected actual) then
    failwith
      (Printf.sprintf
         "Expected lock_policy %s, got %s"
         (pp_lock_policy expected)
         (pp_lock_policy actual))

let test_lock_policy_default =
  Oth.test ~name:"lock_policy: defaults to strict" (fun _ ->
      assert_lock_policy
        V1.Workflows.Entry.Lock_policy.Strict
        (V1.lock_policy (config_of_json (`Assoc []))))

let test_lock_policy_global =
  Oth.test ~name:"lock_policy: global value is read" (fun _ ->
      assert_lock_policy
        V1.Workflows.Entry.Lock_policy.Merge
        (V1.lock_policy (config_of_json (`Assoc [ ("lock_policy", `String "merge") ]))))

let test_lock_policy_workflow_inherits =
  Oth.test ~name:"lock_policy: workflow entry inherits the global value" (fun _ ->
      let json =
        `Assoc
          [
            ("lock_policy", `String "apply");
            ("workflows", `List [ `Assoc [ ("tag_query", `String "") ] ]);
          ]
      in
      match V1.workflows (config_of_json json) with
      | [ { V1.Workflows.Entry.lock_policy; _ } ] ->
          assert_lock_policy V1.Workflows.Entry.Lock_policy.Apply lock_policy
      | _ -> failwith "Expected exactly one workflow entry")

let test_lock_policy_workflow_overrides =
  Oth.test ~name:"lock_policy: workflow entry overrides the global value" (fun _ ->
      let json =
        `Assoc
          [
            ("lock_policy", `String "apply");
            ( "workflows",
              `List [ `Assoc [ ("tag_query", `String ""); ("lock_policy", `String "none") ] ] );
          ]
      in
      match V1.workflows (config_of_json json) with
      | [ { V1.Workflows.Entry.lock_policy; _ } ] ->
          assert_lock_policy V1.Workflows.Entry.Lock_policy.None lock_policy
      | _ -> failwith "Expected exactly one workflow entry")

let test_lock_policy_to_version_1_round_trip =
  Oth.test ~name:"lock_policy: global value round-trips through Version_1" (fun _ ->
      let cfg = config_of_json (`Assoc [ ("lock_policy", `String "none") ]) in
      let v1 = V1.to_version_1 cfg in
      match v1.Repo.Version_1.lock_policy with
      | `None -> ()
      | _ -> failwith "Round-trip to Version_1 did not preserve lock_policy")

(* Tests for the requirement that an explicit [plan] step list contains a [plan]
   step and an explicit [apply] step list contains an [apply] step. *)

let workflows_json entries = `Assoc [ ("workflows", `List entries) ]
let step type_ = `Assoc [ ("type", `String type_) ]

let workflow_entry ?apply ?plan tag_query =
  `Assoc
    (("tag_query", `String tag_query)
    :: CCList.filter_map
         CCFun.id
         [
           CCOption.map (fun steps -> ("apply", `List steps)) apply;
           CCOption.map (fun steps -> ("plan", `List steps)) plan;
         ])

let test_workflow_plan_requires_plan_step =
  Oth.test ~name:"workflows: plan steps without a plan step are rejected" (fun _ ->
      let json = workflows_json [ workflow_entry ~plan:[ step "init"; step "checkov" ] "" ] in
      match Oth.Assert.error (V1.of_version_1_json json) with
      | `Workflows_missing_plan_step_err (0, "") -> ()
      | err ->
          Oth.Assert.false_
            (Printf.sprintf
               "Expected Workflows_missing_plan_step_err (0, \"\"), got %s"
               (V1.show_of_version_1_json_err err)))

let test_workflow_apply_requires_apply_step =
  Oth.test ~name:"workflows: apply steps without an apply step are rejected" (fun _ ->
      let json = workflows_json [ workflow_entry ~apply:[ step "init"; step "plan" ] "" ] in
      match Oth.Assert.error (V1.of_version_1_json json) with
      | `Workflows_missing_apply_step_err (0, "") -> ()
      | err ->
          Oth.Assert.false_
            (Printf.sprintf
               "Expected Workflows_missing_apply_step_err (0, \"\"), got %s"
               (V1.show_of_version_1_json_err err)))

let test_workflow_empty_plan_rejected =
  Oth.test ~name:"workflows: an explicitly empty plan step list is rejected" (fun _ ->
      let json = workflows_json [ workflow_entry ~plan:[] "" ] in
      match Oth.Assert.error (V1.of_version_1_json json) with
      | `Workflows_missing_plan_step_err (0, "") -> ()
      | err ->
          Oth.Assert.false_
            (Printf.sprintf
               "Expected Workflows_missing_plan_step_err (0, \"\"), got %s"
               (V1.show_of_version_1_json_err err)))

let test_workflow_omitted_steps_use_defaults =
  Oth.test ~name:"workflows: omitting plan and apply uses the defaults" (fun _ ->
      let json = workflows_json [ workflow_entry "" ] in
      let cfg = Oth.Assert.ok_pp ~pp:V1.pp_of_version_1_json_err (V1.of_version_1_json json) in
      let { V1.Workflows.Entry.apply; plan; _ } = Oth.Assert.List.length_one (V1.workflows cfg) in
      let module Op = V1.Workflows.Entry.Op in
      let module Op_list = V1.Workflows.Entry.Op_list in
      Oth.Assert.eq
        ~eq:Op_list.equal
        ~pp:Op_list.pp
        [ Op.Init (V1.Workflow_step.Init.make ()); Op.Plan (V1.Workflow_step.Plan.make ()) ]
        plan;
      Oth.Assert.eq
        ~eq:Op_list.equal
        ~pp:Op_list.pp
        [ Op.Init (V1.Workflow_step.Init.make ()); Op.Apply (V1.Workflow_step.Apply.make ()) ]
        apply;
      ())

let test_workflow_extra_steps_allowed =
  Oth.test ~name:"workflows: extra steps around plan and apply are allowed" (fun _ ->
      let json =
        workflows_json
          [
            workflow_entry
              ~plan:[ step "init"; step "plan"; step "checkov" ]
              ~apply:[ step "checkov"; step "init"; step "apply" ]
              "";
          ]
      in
      let cfg = Oth.Assert.ok_pp ~pp:V1.pp_of_version_1_json_err (V1.of_version_1_json json) in
      Oth.Assert.List.length ~expected:1 (V1.workflows cfg);
      ())

let test_workflow_missing_step_reports_index =
  Oth.test ~name:"workflows: the reported index identifies the offending entry" (fun _ ->
      let json =
        workflows_json
          [
            workflow_entry ~plan:[ step "init"; step "plan" ] "dir:foo";
            workflow_entry ~plan:[ step "init" ] "dir:bar";
          ]
      in
      match Oth.Assert.error (V1.of_version_1_json json) with
      | `Workflows_missing_plan_step_err (1, "dir:bar") -> ()
      | err ->
          Oth.Assert.false_
            (Printf.sprintf
               "Expected Workflows_missing_plan_step_err (1, \"dir:bar\"), got %s"
               (V1.show_of_version_1_json_err err)))

let test =
  Oth.parallel
    [
      test_of_version_1_json_minimal;
      test_of_version_1_json_with_version;
      test_to_version_1_round_trip;
      test_lock_policy_default;
      test_lock_policy_global;
      test_lock_policy_workflow_inherits;
      test_lock_policy_workflow_overrides;
      test_lock_policy_to_version_1_round_trip;
      test_workflow_plan_requires_plan_step;
      test_workflow_apply_requires_apply_step;
      test_workflow_empty_plan_rejected;
      test_workflow_omitted_steps_use_defaults;
      test_workflow_extra_steps_allowed;
      test_workflow_missing_step_reports_index;
    ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
