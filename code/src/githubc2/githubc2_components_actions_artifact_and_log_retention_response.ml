module Primary = struct
  type t = {
    days : int;
    maximum_allowed_days : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
