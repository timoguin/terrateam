module Primary = struct
  module Configuration = struct
    module Primary = struct
      module Iterations = struct
        type t = Githubc2_components_projects_v2_iteration_settings.t list
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        duration : int option; [@default None]
        iterations : Iterations.t option; [@default None]
        start_day : int option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Data_type = struct
    let t_of_yojson = function
      | `String "assignees" -> Ok `Assignees
      | `String "date" -> Ok `Date
      | `String "issue_type" -> Ok `Issue_type
      | `String "iteration" -> Ok `Iteration
      | `String "labels" -> Ok `Labels
      | `String "linked_pull_requests" -> Ok `Linked_pull_requests
      | `String "milestone" -> Ok `Milestone
      | `String "number" -> Ok `Number
      | `String "parent_issue" -> Ok `Parent_issue
      | `String "repository" -> Ok `Repository
      | `String "reviewers" -> Ok `Reviewers
      | `String "single_select" -> Ok `Single_select
      | `String "sub_issues_progress" -> Ok `Sub_issues_progress
      | `String "text" -> Ok `Text
      | `String "title" -> Ok `Title
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Assignees -> `String "assignees"
      | `Date -> `String "date"
      | `Issue_type -> `String "issue_type"
      | `Iteration -> `String "iteration"
      | `Labels -> `String "labels"
      | `Linked_pull_requests -> `String "linked_pull_requests"
      | `Milestone -> `String "milestone"
      | `Number -> `String "number"
      | `Parent_issue -> `String "parent_issue"
      | `Repository -> `String "repository"
      | `Reviewers -> `String "reviewers"
      | `Single_select -> `String "single_select"
      | `Sub_issues_progress -> `String "sub_issues_progress"
      | `Text -> `String "text"
      | `Title -> `String "title"

    type t =
      ([ `Assignees
       | `Date
       | `Issue_type
       | `Iteration
       | `Labels
       | `Linked_pull_requests
       | `Milestone
       | `Number
       | `Parent_issue
       | `Repository
       | `Reviewers
       | `Single_select
       | `Sub_issues_progress
       | `Text
       | `Title
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Options = struct
    type t = Githubc2_components_projects_v2_single_select_options.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    configuration : Configuration.t option; [@default None]
    created_at : string;
    data_type : Data_type.t;
    id : int;
    issue_field_id : int option; [@default None]
    name : string;
    node_id : string option; [@default None]
    options : Options.t option; [@default None]
    project_url : string;
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
