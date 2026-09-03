module Primary = struct
  module Payload = struct
    type t =
      | Create_event of Githubc2_components_create_event.t
      | Delete_event of Githubc2_components_delete_event.t
      | Discussion_event of Githubc2_components_discussion_event.t
      | Issues_event of Githubc2_components_issues_event.t
      | Issue_comment_event of Githubc2_components_issue_comment_event.t
      | Fork_event of Githubc2_components_fork_event.t
      | Gollum_event of Githubc2_components_gollum_event.t
      | Member_event of Githubc2_components_member_event.t
      | Public_event of Githubc2_components_public_event.t
      | Push_event of Githubc2_components_push_event.t
      | Pull_request_event of Githubc2_components_pull_request_event.t
      | Pull_request_review_comment_event of Githubc2_components_pull_request_review_comment_event.t
      | Pull_request_review_event of Githubc2_components_pull_request_review_event.t
      | Commit_comment_event of Githubc2_components_commit_comment_event.t
      | Release_event of Githubc2_components_release_event.t
      | Watch_event of Githubc2_components_watch_event.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
         [
           (fun v -> map (fun v -> Create_event v) (Githubc2_components_create_event.of_yojson v));
           (fun v -> map (fun v -> Delete_event v) (Githubc2_components_delete_event.of_yojson v));
           (fun v ->
             map (fun v -> Discussion_event v) (Githubc2_components_discussion_event.of_yojson v));
           (fun v -> map (fun v -> Issues_event v) (Githubc2_components_issues_event.of_yojson v));
           (fun v ->
             map
               (fun v -> Issue_comment_event v)
               (Githubc2_components_issue_comment_event.of_yojson v));
           (fun v -> map (fun v -> Fork_event v) (Githubc2_components_fork_event.of_yojson v));
           (fun v -> map (fun v -> Gollum_event v) (Githubc2_components_gollum_event.of_yojson v));
           (fun v -> map (fun v -> Member_event v) (Githubc2_components_member_event.of_yojson v));
           (fun v -> map (fun v -> Public_event v) (Githubc2_components_public_event.of_yojson v));
           (fun v -> map (fun v -> Push_event v) (Githubc2_components_push_event.of_yojson v));
           (fun v ->
             map
               (fun v -> Pull_request_event v)
               (Githubc2_components_pull_request_event.of_yojson v));
           (fun v ->
             map
               (fun v -> Pull_request_review_comment_event v)
               (Githubc2_components_pull_request_review_comment_event.of_yojson v));
           (fun v ->
             map
               (fun v -> Pull_request_review_event v)
               (Githubc2_components_pull_request_review_event.of_yojson v));
           (fun v ->
             map
               (fun v -> Commit_comment_event v)
               (Githubc2_components_commit_comment_event.of_yojson v));
           (fun v -> map (fun v -> Release_event v) (Githubc2_components_release_event.of_yojson v));
           (fun v -> map (fun v -> Watch_event v) (Githubc2_components_watch_event.of_yojson v));
         ])

    let to_yojson = function
      | Create_event v -> Githubc2_components_create_event.to_yojson v
      | Delete_event v -> Githubc2_components_delete_event.to_yojson v
      | Discussion_event v -> Githubc2_components_discussion_event.to_yojson v
      | Issues_event v -> Githubc2_components_issues_event.to_yojson v
      | Issue_comment_event v -> Githubc2_components_issue_comment_event.to_yojson v
      | Fork_event v -> Githubc2_components_fork_event.to_yojson v
      | Gollum_event v -> Githubc2_components_gollum_event.to_yojson v
      | Member_event v -> Githubc2_components_member_event.to_yojson v
      | Public_event v -> Githubc2_components_public_event.to_yojson v
      | Push_event v -> Githubc2_components_push_event.to_yojson v
      | Pull_request_event v -> Githubc2_components_pull_request_event.to_yojson v
      | Pull_request_review_comment_event v ->
          Githubc2_components_pull_request_review_comment_event.to_yojson v
      | Pull_request_review_event v -> Githubc2_components_pull_request_review_event.to_yojson v
      | Commit_comment_event v -> Githubc2_components_commit_comment_event.to_yojson v
      | Release_event v -> Githubc2_components_release_event.to_yojson v
      | Watch_event v -> Githubc2_components_watch_event.to_yojson v
  end

  module Repo = struct
    module Primary = struct
      type t = {
        id : int;
        name : string;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    actor : Githubc2_components_actor.t;
    created_at : string option; [@default None]
    id : string;
    org : Githubc2_components_actor.t option; [@default None]
    payload : Payload.t;
    public : bool;
    repo : Repo.t;
    type_ : string option; [@default None] [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
