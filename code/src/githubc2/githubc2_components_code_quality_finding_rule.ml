module Primary = struct
  module Category = struct
    let t_of_yojson = function
      | `String "maintainability" -> Ok `Maintainability
      | `String "none" -> Ok `None
      | `String "reliability" -> Ok `Reliability
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Maintainability -> `String "maintainability"
      | `None -> `String "none"
      | `Reliability -> `String "reliability"

    type t =
      ([ `Maintainability
       | `None
       | `Reliability
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Severity = struct
    let t_of_yojson = function
      | `String "error" -> Ok `Error
      | `String "none" -> Ok `None
      | `String "note" -> Ok `Note
      | `String "warning" -> Ok `Warning
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Error -> `String "error"
      | `None -> `String "none"
      | `Note -> `String "note"
      | `Warning -> `String "warning"

    type t =
      ([ `Error
       | `None
       | `Note
       | `Warning
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    category : Category.t;
    description : string;
    help : string option; [@default None]
    id : string;
    severity : Severity.t;
    title : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
