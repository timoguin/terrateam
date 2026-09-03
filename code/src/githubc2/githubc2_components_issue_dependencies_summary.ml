module Primary = struct
  type t = {
    blocked_by : int;
    blocking : int;
    total_blocked_by : int;
    total_blocking : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
