module Primary = struct
  type t = {
    html_url : string;
    run_url : string;
    workflow_run_id : int64;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
