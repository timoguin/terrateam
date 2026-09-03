module Primary = struct
  type t = {
    full_ref : string;
    pusher_type : string;
    ref_ : string; [@key "ref"]
    ref_type : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
