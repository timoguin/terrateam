module Owner_type = struct
  let t_of_yojson = function
    | `String "api" -> Ok `Api
    | `String "system" -> Ok `System
    | `String "user" -> Ok `User
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Api -> `String "api"
    | `System -> `String "system"
    | `User -> `String "user"

  type t =
    ([ `Api
     | `System
     | `User
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  created_at : string;
  expiration : string option; [@default None]
  id : string;
  name : string;
  owner_id : string;
  owner_name : string;
  owner_type : Owner_type.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
