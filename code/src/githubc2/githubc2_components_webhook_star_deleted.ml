module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "deleted" -> Ok "deleted"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Starred_at = struct
    type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    action : Action.t;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user_webhooks.t;
    starred_at : Starred_at.t option;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)