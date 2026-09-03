module Primary = struct
  module Parameters = struct
    module Primary = struct
      module Allowed_merge_methods = struct
        module Items = struct
          let t_of_yojson = function
            | `String "merge" -> Ok `Merge
            | `String "rebase" -> Ok `Rebase
            | `String "squash" -> Ok `Squash
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          let t_to_yojson = function
            | `Merge -> `String "merge"
            | `Rebase -> `String "rebase"
            | `Squash -> `String "squash"

          type t =
            ([ `Merge
             | `Rebase
             | `Squash
             ]
            [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Required_reviewers = struct
        type t = Githubc2_components_repository_rule_params_required_reviewer_configuration.t list
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        allowed_merge_methods : Allowed_merge_methods.t option; [@default None]
        dismiss_stale_reviews_on_push : bool;
        dismissal_restriction :
          Githubc2_components_repository_rule_params_dismissal_restriction.t option;
            [@default None]
        require_code_owner_review : bool;
        require_last_push_approval : bool;
        required_approving_review_count : int;
        required_review_thread_resolution : bool;
        required_reviewers : Required_reviewers.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Type = struct
    let t_of_yojson = function
      | `String "pull_request" -> Ok `Pull_request
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Pull_request -> `String "pull_request"

    type t = ([ `Pull_request ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    parameters : Parameters.t option; [@default None]
    type_ : Type.t; [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
