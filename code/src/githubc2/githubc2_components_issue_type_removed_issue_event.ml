module Primary = struct
  type t = {
    actor : Githubc2_components_simple_user.t;
    commit_id : string option; [@default None]
    commit_url : string option; [@default None]
    created_at : string;
    event : string;
    id : int;
    intent : Githubc2_components_nullable_issue_event_intent.t option; [@default None]
    node_id : string;
    performed_via_github_app : Githubc2_components_nullable_integration.t option; [@default None]
    prev_issue_type : Githubc2_components_issue_type_webhook.t option; [@default None]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
