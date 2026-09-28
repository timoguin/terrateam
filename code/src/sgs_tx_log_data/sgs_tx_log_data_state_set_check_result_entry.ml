module Primary = struct
  type t = {
    config_addr : string;
    object_addr : string option; [@default None]
    status : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, make, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
