module Lock_policy = struct
  let t_of_yojson = function
    | `String "apply" -> Ok `Apply
    | `String "merge" -> Ok `Merge
    | `String "none" -> Ok `None
    | `String "strict" -> Ok `Strict
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Apply -> `String "apply"
    | `Merge -> `String "merge"
    | `None -> `String "none"
    | `Strict -> `String "strict"

  type t =
    ([ `Apply
     | `Merge
     | `None
     | `Strict
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Storage = struct
  module Plans = struct
    type t =
      | Storage_plan_terrateam of Terrat_repo_config_storage_plan_terrateam.t
      | Storage_plan_cmd of Terrat_repo_config_storage_plan_cmd.t
      | Storage_plan_none of Terrat_repo_config_storage_plan_none.t
      | Storage_plan_s3 of Terrat_repo_config_storage_plan_s3.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
         [
           (fun v ->
             map
               (fun v -> Storage_plan_terrateam v)
               (Terrat_repo_config_storage_plan_terrateam.of_yojson v));
           (fun v ->
             map (fun v -> Storage_plan_cmd v) (Terrat_repo_config_storage_plan_cmd.of_yojson v));
           (fun v ->
             map (fun v -> Storage_plan_none v) (Terrat_repo_config_storage_plan_none.of_yojson v));
           (fun v ->
             map (fun v -> Storage_plan_s3 v) (Terrat_repo_config_storage_plan_s3.of_yojson v));
         ])

    let to_yojson = function
      | Storage_plan_terrateam v -> Terrat_repo_config_storage_plan_terrateam.to_yojson v
      | Storage_plan_cmd v -> Terrat_repo_config_storage_plan_cmd.to_yojson v
      | Storage_plan_none v -> Terrat_repo_config_storage_plan_none.to_yojson v
      | Storage_plan_s3 v -> Terrat_repo_config_storage_plan_s3.to_yojson v
  end

  type t = { plans : Plans.t option [@default None] }
  [@@deriving yojson { strict = true; meta = true }, make, show, eq]
end

type t = {
  apply : Terrat_repo_config_workflow_op_list.t option; [@default None]
  cdktf : bool; [@default false]
  engine : Terrat_repo_config_engine.t option; [@default None]
  environment : string option; [@default None]
  integrations : Terrat_repo_config_integrations.t option; [@default None]
  lock_policy : Lock_policy.t option; [@default None]
  plan : Terrat_repo_config_workflow_op_list.t option; [@default None]
  runs_on : Terrat_repo_config_runs_on.t option; [@default None]
  storage : Storage.t option; [@default None]
  tag_query : string;
  terraform_version : string option; [@default None]
  terragrunt : bool; [@default false]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
