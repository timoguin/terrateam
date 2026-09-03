module Primary = struct
  module Inclusion_source = struct
    let t_of_yojson = function
      | `String "enterprise" -> Ok `Enterprise
      | `String "organization" -> Ok `Organization
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Enterprise -> `String "enterprise"
      | `Organization -> `String "organization"

    type t =
      ([ `Enterprise
       | `Organization
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    custom_property_name : string;
    inclusion_source : Inclusion_source.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
