module Primary = struct
  module Comments = struct
    type t = Githubc2_components_pull_request_review_comment.t list
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    comments : Comments.t option; [@default None]
    event : string option; [@default None]
    node_id : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)