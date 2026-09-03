module Primary = struct
  type t = {
    before : string;
    head : string;
    push_id : int;
    ref_ : string; [@key "ref"]
    repository_id : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
