module Mode = struct
  let t_of_yojson = function
    | `String "data" -> Ok `Data
    | `String "managed" -> Ok `Managed
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Data -> `String "data"
    | `Managed -> `String "managed"

  type t =
    ([ `Data
     | `Managed
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  address : string;
  fq_address : string;
  mode : Mode.t;
  module_ : string option; [@key "module"] [@default None]
  moved_from_address : string option; [@default None]
  name : string;
  provider : string option; [@default None]
  type_ : string; [@key "type"]
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
