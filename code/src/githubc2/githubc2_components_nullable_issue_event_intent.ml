module Primary = struct
  module Confidence = struct
    let t_of_yojson = function
      | `String "HIGH" -> Ok `HIGH
      | `String "LOW" -> Ok `LOW
      | `String "MEDIUM" -> Ok `MEDIUM
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `HIGH -> `String "HIGH"
      | `LOW -> `String "LOW"
      | `MEDIUM -> `String "MEDIUM"

    type t =
      ([ `HIGH
       | `LOW
       | `MEDIUM
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    confidence : Confidence.t option; [@default None]
    rationale : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
