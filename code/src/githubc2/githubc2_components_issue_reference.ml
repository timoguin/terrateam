module Primary = struct
  module Issue_type_ = struct
    module Primary = struct
      type t = {
        color : string option; [@default None]
        id : int;
        name : string;
        node_id : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    issue_type : Issue_type_.t option; [@default None]
    number : int;
    repository : Githubc2_components_simple_repository.t;
    state : string;
    state_reason : string option; [@default None]
    title : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
