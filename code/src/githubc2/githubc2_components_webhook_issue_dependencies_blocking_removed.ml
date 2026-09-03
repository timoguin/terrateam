module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "blocking_removed" -> Ok `Blocking_removed
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Blocking_removed -> `String "blocking_removed"

    type t = ([ `Blocking_removed ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    action : Action.t;
    blocked_issue : Githubc2_components_issue.t option; [@default None]
    blocked_issue_id : float option; [@default None]
    blocked_issue_repo : Githubc2_components_repository.t option; [@default None]
    blocking_issue : Githubc2_components_issue.t option; [@default None]
    blocking_issue_id : float option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t;
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
