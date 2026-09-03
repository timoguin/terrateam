module Primary = struct
  module Assignees = struct
    type t = Githubc2_components_simple_user.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Issue_field_values = struct
    type t = Githubc2_components_issue_field_value.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Labels = struct
    module Items = struct
      module Primary = struct
        type t = {
          color : string option; [@default None]
          default : bool option; [@default None]
          description : string option; [@default None]
          id : int64 option; [@default None]
          name : string option; [@default None]
          node_id : string option; [@default None]
          url : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Pull_request_ = struct
    module Primary = struct
      type t = {
        diff_url : string option; [@default None]
        html_url : string option; [@default None]
        merged_at : string option; [@default None]
        patch_url : string option; [@default None]
        url : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    active_lock_reason : string option; [@default None]
    assignee : Githubc2_components_nullable_simple_user.t option; [@default None]
    assignees : Assignees.t option; [@default None]
    author_association : Githubc2_components_author_association.t;
    body : string option; [@default None]
    body_html : string option; [@default None]
    body_text : string option; [@default None]
    closed_at : string option; [@default None]
    comments : int;
    comments_url : string;
    created_at : string;
    draft : bool option; [@default None]
    events_url : string;
    html_url : string;
    id : int64;
    issue_dependencies_summary : Githubc2_components_issue_dependencies_summary.t option;
        [@default None]
    issue_field_values : Issue_field_values.t option; [@default None]
    labels : Labels.t;
    labels_url : string;
    locked : bool;
    milestone : Githubc2_components_nullable_milestone.t option; [@default None]
    node_id : string;
    number : int;
    performed_via_github_app : Githubc2_components_nullable_integration.t option; [@default None]
    pinned_comment : Githubc2_components_nullable_issue_comment.t option; [@default None]
    pull_request : Pull_request_.t option; [@default None]
    reactions : Githubc2_components_reaction_rollup.t option; [@default None]
    repository : Githubc2_components_repository.t option; [@default None]
    repository_url : string;
    score : float;
    state : string;
    state_reason : string option; [@default None]
    sub_issues_summary : Githubc2_components_sub_issues_summary.t option; [@default None]
    text_matches : Githubc2_components_search_result_text_matches.t option; [@default None]
    timeline_url : string option; [@default None]
    title : string;
    type_ : Githubc2_components_issue_type.t option; [@default None] [@key "type"]
    updated_at : string;
    url : string;
    user : Githubc2_components_nullable_simple_user.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
