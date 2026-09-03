module Primary = struct
  type t = {
    id : int;
    latest_version : string;
    name : string;
    platform : string;
    source : string;
    state : string;
    total_versions_size : int;
    versions_count : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
