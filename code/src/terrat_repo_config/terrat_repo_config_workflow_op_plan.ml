module Env = struct
  module Additional = struct
    type t = string [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
end

module Extra_args = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show]
end

module Type = struct
  let t_of_yojson = function
    | `String "plan" -> Ok "plan"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

type t = {
  env : Env.t option; [@default None]
  extra_args : Extra_args.t option; [@default None]
  terraform_version : Terrat_repo_config_terraform_version.t option; [@default None]
  terragrunt : bool; [@default false]
  type_ : Type.t; [@key "type"]
}
[@@deriving yojson { strict = true; meta = true }, make, show]