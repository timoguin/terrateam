module Primary = struct
  module Forkee = struct
    module Primary = struct
      module Pull_request_creation_policy = struct
        let t_of_yojson = function
          | `String "all" -> Ok `All
          | `String "collaborators_only" -> Ok `Collaborators_only
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `All -> `String "all"
          | `Collaborators_only -> `String "collaborators_only"

        type t =
          ([ `All
           | `Collaborators_only
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Topics = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        allow_forking : bool option; [@default None]
        archive_url : string option; [@default None]
        archived : bool option; [@default None]
        assignees_url : string option; [@default None]
        blobs_url : string option; [@default None]
        branches_url : string option; [@default None]
        clone_url : string option; [@default None]
        collaborators_url : string option; [@default None]
        comments_url : string option; [@default None]
        commits_url : string option; [@default None]
        compare_url : string option; [@default None]
        contents_url : string option; [@default None]
        contributors_url : string option; [@default None]
        created_at : string option; [@default None]
        default_branch : string option; [@default None]
        deployments_url : string option; [@default None]
        description : string option; [@default None]
        disabled : bool option; [@default None]
        downloads_url : string option; [@default None]
        events_url : string option; [@default None]
        fork : bool option; [@default None]
        forks : int option; [@default None]
        forks_count : int option; [@default None]
        forks_url : string option; [@default None]
        full_name : string option; [@default None]
        git_commits_url : string option; [@default None]
        git_refs_url : string option; [@default None]
        git_tags_url : string option; [@default None]
        git_url : string option; [@default None]
        has_discussions : bool option; [@default None]
        has_downloads : bool option; [@default None]
        has_issues : bool option; [@default None]
        has_pages : bool option; [@default None]
        has_projects : bool option; [@default None]
        has_pull_requests : bool option; [@default None]
        has_wiki : bool option; [@default None]
        homepage : string option; [@default None]
        hooks_url : string option; [@default None]
        html_url : string option; [@default None]
        id : int option; [@default None]
        is_template : bool option; [@default None]
        issue_comment_url : string option; [@default None]
        issue_events_url : string option; [@default None]
        issues_url : string option; [@default None]
        keys_url : string option; [@default None]
        labels_url : string option; [@default None]
        language : string option; [@default None]
        languages_url : string option; [@default None]
        license : Githubc2_components_nullable_license_simple.t option; [@default None]
        merges_url : string option; [@default None]
        milestones_url : string option; [@default None]
        mirror_url : string option; [@default None]
        name : string option; [@default None]
        node_id : string option; [@default None]
        notifications_url : string option; [@default None]
        open_issues : int option; [@default None]
        open_issues_count : int option; [@default None]
        owner : Githubc2_components_simple_user.t option; [@default None]
        private_ : bool option; [@default None] [@key "private"]
        public : bool option; [@default None]
        pull_request_creation_policy : Pull_request_creation_policy.t option; [@default None]
        pulls_url : string option; [@default None]
        pushed_at : string option; [@default None]
        releases_url : string option; [@default None]
        size : int option; [@default None]
        ssh_url : string option; [@default None]
        stargazers_count : int option; [@default None]
        stargazers_url : string option; [@default None]
        statuses_url : string option; [@default None]
        subscribers_url : string option; [@default None]
        subscription_url : string option; [@default None]
        svn_url : string option; [@default None]
        tags_url : string option; [@default None]
        teams_url : string option; [@default None]
        topics : Topics.t option; [@default None]
        trees_url : string option; [@default None]
        updated_at : string option; [@default None]
        url : string option; [@default None]
        visibility : string option; [@default None]
        watchers : int option; [@default None]
        watchers_count : int option; [@default None]
        web_commit_signoff_required : bool option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : string;
    forkee : Forkee.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
