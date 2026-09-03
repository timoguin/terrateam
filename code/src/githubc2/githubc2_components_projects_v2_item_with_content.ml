module Primary = struct
  module Content = struct
    include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
  end

  module Fields = struct
    module Items = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    archived_at : string option; [@default None]
    content : Content.t option; [@default None]
    content_type : Githubc2_components_projects_v2_item_content_type.t;
    created_at : string;
    creator : Githubc2_components_simple_user.t option; [@default None]
    fields : Fields.t option; [@default None]
    id : float;
    item_url : string option; [@default None]
    node_id : string option; [@default None]
    project_url : string option; [@default None]
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
