type t = {
  admin_cicd_variables : bool option; [@default None]
  admin_compliance_framework : bool option; [@default None]
  admin_group_member : bool option; [@default None]
  admin_integrations : bool option; [@default None]
  admin_merge_request : bool option; [@default None]
  admin_protected_branch : bool option; [@default None]
  admin_protected_environments : bool option; [@default None]
  admin_push_rules : bool option; [@default None]
  admin_runners : bool option; [@default None]
  admin_security_testing : bool option; [@default None]
  admin_terraform_state : bool option; [@default None]
  admin_vulnerability : bool option; [@default None]
  admin_web_hook : bool option; [@default None]
  archive_project : bool option; [@default None]
  base_access_level : int option; [@default None]
  description : string option; [@default None]
  group_id : int option; [@default None]
  id : int option; [@default None]
  manage_deploy_tokens : bool option; [@default None]
  manage_group_access_tokens : bool option; [@default None]
  manage_merge_request_settings : bool option; [@default None]
  manage_project_access_tokens : bool option; [@default None]
  manage_protected_tags : bool option; [@default None]
  manage_security_policy_link : bool option; [@default None]
  name : string option; [@default None]
  read_admin_cicd : bool option; [@default None]
  read_admin_dashboard : bool option; [@default None]
  read_admin_monitoring : bool option; [@default None]
  read_admin_subscription : bool option; [@default None]
  read_admin_users : bool option; [@default None]
  read_code : bool option; [@default None]
  read_compliance_dashboard : bool option; [@default None]
  read_crm_contact : bool option; [@default None]
  read_dependency : bool option; [@default None]
  read_runners : bool option; [@default None]
  read_vulnerability : bool option; [@default None]
  remove_group : bool option; [@default None]
  remove_project : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
