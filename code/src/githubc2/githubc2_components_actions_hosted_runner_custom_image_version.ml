module Primary = struct
  type t = {
    created_on : string;
    size_gb : int;
    state : string;
    state_details : string;
    version : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
