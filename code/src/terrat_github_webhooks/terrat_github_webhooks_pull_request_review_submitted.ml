module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "submitted" -> Ok "submitted"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    action : Action.t;
    installation : Terrat_github_webhooks_installation_lite.t option; [@default None]
    organization : Terrat_github_webhooks_organization.t option; [@default None]
    repository : Terrat_github_webhooks_repository.t;
    sender : Terrat_github_webhooks_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, make, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)