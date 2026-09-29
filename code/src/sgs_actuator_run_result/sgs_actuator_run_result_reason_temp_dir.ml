module Kind = struct
  let t_of_yojson = function
    | `String "temp_dir" -> Ok `Temp_dir
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Temp_dir -> `String "temp_dir"

  type t = ([ `Temp_dir ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { kind : Kind.t } [@@deriving yojson { strict = false; meta = true }, make, show, eq]
