module Primary = struct
  module Review = struct
    module Primary = struct
      module Links_ = struct
        module Primary = struct
          module Html = struct
            module Primary = struct
              type t = { href : string }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Pull_request_ = struct
            module Primary = struct
              type t = { href : string }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = {
            html : Html.t;
            pull_request : Pull_request_.t;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        links_ : Links_.t option; [@default None] [@key "_links"]
        body : string option; [@default None]
        commit_id : string option; [@default None]
        html_url : string option; [@default None]
        id : int option; [@default None]
        node_id : string option; [@default None]
        pull_request_url : string option; [@default None]
        state : string option; [@default None]
        submitted_at : string option; [@default None]
        updated_at : string option; [@default None]
        user : Githubc2_components_nullable_simple_user.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : string;
    pull_request : Githubc2_components_pull_request_minimal.t;
    review : Review.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
