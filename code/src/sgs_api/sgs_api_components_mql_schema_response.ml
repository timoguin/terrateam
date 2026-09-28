module Tables = struct
  include
    Json_schema.Additional_properties.Make
      (Json_schema.Empty_obj)
      (Sgs_api_components_mql_schema_table)
end

type t = {
  default_limit : int;
  max_limit : int;
  tables : Tables.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
