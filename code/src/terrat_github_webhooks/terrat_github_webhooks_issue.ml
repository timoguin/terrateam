module Pull_request_ = struct
  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
end

type t = {
  number : int;
  pull_request : Pull_request_.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
