module Type = struct
  let t_of_yojson = function
    | `String "Bot" -> Ok `Bot
    | `String "Organization" -> Ok `Organization
    | `String "User" -> Ok `User
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Bot -> `String "Bot"
    | `Organization -> `String "Organization"
    | `User -> `String "User"

  type t =
    ([ `Bot
     | `Organization
     | `User
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  login : string;
  type_ : Type.t; [@key "type"]
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
