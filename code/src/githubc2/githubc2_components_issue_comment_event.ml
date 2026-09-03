module Primary = struct
  type t = {
    action : string;
    comment : Githubc2_components_issue_comment.t;
    issue : Githubc2_components_issue.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
