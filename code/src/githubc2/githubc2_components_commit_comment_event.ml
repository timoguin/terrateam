module Primary = struct
  module Comment = struct
    module Primary = struct
      type t = {
        body : string option; [@default None]
        commit_id : string option; [@default None]
        created_at : string option; [@default None]
        html_url : string option; [@default None]
        id : int option; [@default None]
        line : int option; [@default None]
        node_id : string option; [@default None]
        path : string option; [@default None]
        position : int option; [@default None]
        reactions : Githubc2_components_reaction_rollup.t option; [@default None]
        updated_at : string option; [@default None]
        url : string option; [@default None]
        user : Githubc2_components_nullable_simple_user.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : string;
    comment : Comment.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
