module Kind = struct
  let t_of_yojson = function
    | `String "client_create" -> Ok `Client_create
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Client_create -> `String "client_create"

  type t = ([ `Client_create ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { kind : Kind.t } [@@deriving yojson { strict = false; meta = true }, make, show, eq]
