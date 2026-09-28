module Components = struct
  type t = Sgs_api_components_cost_component.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Tags = struct
  module Additional = struct
    type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
end

type t = {
  address : string;
  cloud_resource_id : string option; [@default None]
  components : Components.t option; [@default None]
  hourly_cost : string option; [@default None]
  monthly_cost : string option; [@default None]
  no_price : bool;
  provider : string option; [@default None]
  region : string option; [@default None]
  supported : bool;
  tags : Tags.t option; [@default None]
  type_ : string; [@key "type"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
