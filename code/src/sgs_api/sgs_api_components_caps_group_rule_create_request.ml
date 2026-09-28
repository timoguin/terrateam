module Condition = struct
  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
end

type t = {
  condition : Condition.t;
  description : string option; [@default None]
  grant : Sg_caps_wire_capabilities.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
