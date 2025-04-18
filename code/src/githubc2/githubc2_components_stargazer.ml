module Primary = struct
  type t = {
    starred_at : string;
    user : Githubc2_components_nullable_simple_user.t option;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
