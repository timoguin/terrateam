module Primary = struct
  type t = {
    actor : Githubc2_components_nullable_simple_user.t option; [@default None]
    assignee : Githubc2_components_nullable_simple_user.t option; [@default None]
    assigner : Githubc2_components_nullable_simple_user.t option; [@default None]
    author_association : Githubc2_components_author_association.t option; [@default None]
    blocked_by : Githubc2_components_nullable_issue_reference.t option; [@default None]
    blocking : Githubc2_components_nullable_issue_reference.t option; [@default None]
    commit_id : string option; [@default None]
    commit_url : string option; [@default None]
    created_at : string;
    dismissed_review : Githubc2_components_issue_event_dismissed_review.t option; [@default None]
    event : string;
    id : int64;
    intent : Githubc2_components_nullable_issue_event_intent.t option; [@default None]
    issue : Githubc2_components_nullable_issue.t option; [@default None]
    issue_type : Githubc2_components_issue_type_webhook.t option; [@default None]
    label : Githubc2_components_issue_event_label.t option; [@default None]
    lock_reason : string option; [@default None]
    milestone : Githubc2_components_issue_event_milestone.t option; [@default None]
    node_id : string;
    parent_issue : Githubc2_components_nullable_issue_reference.t option; [@default None]
    performed_via_github_app : Githubc2_components_nullable_integration.t option; [@default None]
    prev_issue_type : Githubc2_components_issue_type_webhook.t option; [@default None]
    project_card : Githubc2_components_issue_event_project_card.t option; [@default None]
    rename : Githubc2_components_issue_event_rename.t option; [@default None]
    requested_reviewer : Githubc2_components_nullable_simple_user.t option; [@default None]
    requested_team : Githubc2_components_team.t option; [@default None]
    review_requester : Githubc2_components_nullable_simple_user.t option; [@default None]
    sub_issue : Githubc2_components_nullable_issue_reference.t option; [@default None]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
