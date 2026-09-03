module Primary = struct
  type t = {
    body : string option; [@default None]
    created_at : string;
    id : float;
    node_id : string;
    title : string;
    updated_at : string;
    user : Githubc2_components_nullable_simple_user.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
