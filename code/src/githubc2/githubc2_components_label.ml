module Primary = struct
  type t = {
    color : string;
    default : bool;
    description : string option;
    id : int64;
    name : string;
    node_id : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)