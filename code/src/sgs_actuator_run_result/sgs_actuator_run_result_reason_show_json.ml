module Kind = struct
  let t_of_yojson = function
    | `String "show_json" -> Ok `Show_json
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Show_json -> `String "show_json"

  type t = ([ `Show_json ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  kind : Kind.t;
  stderr : string;
  stdout : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
