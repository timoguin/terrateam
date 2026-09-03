module Primary = struct
  module Content = struct
    type t =
      | Issue of Githubc2_components_issue.t
      | Pull_request_simple of Githubc2_components_pull_request_simple.t
      | Projects_v2_draft_issue of Githubc2_components_projects_v2_draft_issue.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
         [
           (fun v -> map (fun v -> Issue v) (Githubc2_components_issue.of_yojson v));
           (fun v ->
             map
               (fun v -> Pull_request_simple v)
               (Githubc2_components_pull_request_simple.of_yojson v));
           (fun v ->
             map
               (fun v -> Projects_v2_draft_issue v)
               (Githubc2_components_projects_v2_draft_issue.of_yojson v));
         ])

    let to_yojson = function
      | Issue v -> Githubc2_components_issue.to_yojson v
      | Pull_request_simple v -> Githubc2_components_pull_request_simple.to_yojson v
      | Projects_v2_draft_issue v -> Githubc2_components_projects_v2_draft_issue.to_yojson v
  end

  type t = {
    archived_at : string option; [@default None]
    content : Content.t option; [@default None]
    content_type : Githubc2_components_projects_v2_item_content_type.t;
    created_at : string;
    creator : Githubc2_components_simple_user.t option; [@default None]
    id : float;
    item_url : string option; [@default None]
    node_id : string option; [@default None]
    project_url : string option; [@default None]
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
