module Mode = struct
  let t_of_yojson = function
    | `String "header" -> Ok `Header
    | `String "pull_request" -> Ok `Pull_request
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Header -> `String "header"
    | `Pull_request -> `String "pull_request"

  type t =
    ([ `Header
     | `Pull_request
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Output_details = struct
  type t = { enabled : bool [@default false] }
  [@@deriving yojson { strict = true; meta = true }, make, show, eq]
end

type t = {
  enabled : bool option; [@default None]
  mode : Mode.t; [@default `Pull_request]
  output_details : Output_details.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
