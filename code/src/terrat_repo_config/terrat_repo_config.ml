module Automerge = Terrat_repo_config_automerge
module Dir = Terrat_repo_config_dir
module Hook = Terrat_repo_config_hook
module Hook_list = Terrat_repo_config_hook_list
module Hook_op = Terrat_repo_config_hook_op
module Hook_op_env = Terrat_repo_config_hook_op_env
module Hook_op_run = Terrat_repo_config_hook_op_run
module Hook_op_slack = Terrat_repo_config_hook_op_slack
module Permission = Terrat_repo_config_permission
module Run_on = Terrat_repo_config_run_on
module Tags = Terrat_repo_config_tags
module Terraform_version = Terrat_repo_config_terraform_version
module Version_1 = Terrat_repo_config_version_1
module When_modified = Terrat_repo_config_when_modified
module When_modified_nullable = Terrat_repo_config_when_modified_nullable
module Workflow_entry = Terrat_repo_config_workflow_entry
module Workflow_op_apply = Terrat_repo_config_workflow_op_apply
module Workflow_op_init = Terrat_repo_config_workflow_op_init
module Workflow_op_list = Terrat_repo_config_workflow_op_list
module Workflow_op_plan = Terrat_repo_config_workflow_op_plan

module Event = struct
  type t = Version_1 of Terrat_repo_config_version_1.t [@@deriving show]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
      [ (fun v -> map (fun v -> Version_1 v) (Terrat_repo_config_version_1.of_yojson v)) ])

  let to_yojson = function
    | Version_1 v -> Terrat_repo_config_version_1.to_yojson v
end