module Action = struct
  let t_of_yojson = function
    | `String "edited" -> Ok `Edited
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Edited -> `String "edited"

  type t = ([ `Edited ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Changes = struct
  module Base = struct
    include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
  end

  type t = { base : Base.t option [@default None] }
  [@@deriving yojson { strict = false; meta = true }, make, show, eq]
end

type t = {
  action : Action.t;
  changes : Changes.t;
  installation : Terrat_github_webhooks_installation_lite.t option; [@default None]
  number : int;
  pull_request : Terrat_github_webhooks_pull_request.t;
  repository : Terrat_github_webhooks_repository.t;
  sender : Terrat_github_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
