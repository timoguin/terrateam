module Primary = struct
  type t = {
    ecosystem : string option; [@default None]
    name : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)