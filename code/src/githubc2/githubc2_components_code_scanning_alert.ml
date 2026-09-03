module Primary = struct
  module Assignees = struct
    type t = Githubc2_components_simple_user.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Linked_pull_requests = struct
    type t = Githubc2_components_pull_request_simple.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    assignees : Assignees.t option; [@default None]
    created_at : string;
    dismissal_approved_by : Githubc2_components_nullable_simple_user.t option; [@default None]
    dismissed_at : string option; [@default None]
    dismissed_by : Githubc2_components_nullable_simple_user.t option; [@default None]
    dismissed_comment : string option; [@default None]
    dismissed_reason : Githubc2_components_code_scanning_alert_dismissed_reason.t; [@default None]
    fixed_at : string option; [@default None]
    html_url : string;
    instances_url : string;
    linked_pull_requests : Linked_pull_requests.t option; [@default None]
    most_recent_instance : Githubc2_components_code_scanning_alert_instance.t;
    number : int;
    rule : Githubc2_components_code_scanning_alert_rule.t;
    state : Githubc2_components_code_scanning_alert_state.t; [@default None]
    tool : Githubc2_components_code_scanning_analysis_tool.t;
    updated_at : string option; [@default None]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
