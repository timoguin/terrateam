module Accessible_repositories = struct
  type t = Githubc2_components_nullable_simple_repository.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Default_level = struct
  let t_of_yojson = function
    | `String "internal" -> Ok `Internal
    | `String "public" -> Ok `Public
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Internal -> `String "internal"
    | `Public -> `String "public"

  type t =
    ([ `Internal
     | `Public
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  accessible_repositories : Accessible_repositories.t option; [@default None]
  default_level : Default_level.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
