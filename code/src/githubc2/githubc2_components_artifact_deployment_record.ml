module Primary = struct
  module Runtime_risks = struct
    module Items = struct
      let t_of_yojson = function
        | `String "critical-resource" -> Ok `Critical_resource
        | `String "internet-exposed" -> Ok `Internet_exposed
        | `String "lateral-movement" -> Ok `Lateral_movement
        | `String "sensitive-data" -> Ok `Sensitive_data
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `Critical_resource -> `String "critical-resource"
        | `Internet_exposed -> `String "internet-exposed"
        | `Lateral_movement -> `String "lateral-movement"
        | `Sensitive_data -> `String "sensitive-data"

      type t =
        ([ `Critical_resource
         | `Internet_exposed
         | `Lateral_movement
         | `Sensitive_data
         ]
        [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Tags = struct
    module Additional = struct
      type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
  end

  type t = {
    attestation_id : int option; [@default None]
    cluster : string option; [@default None]
    created_at : string option; [@default None]
    deployment_name : string option; [@default None]
    digest : string option; [@default None]
    id : int option; [@default None]
    logical_environment : string option; [@default None]
    physical_environment : string option; [@default None]
    runtime_risks : Runtime_risks.t option; [@default None]
    tags : Tags.t option; [@default None]
    updated_at : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
