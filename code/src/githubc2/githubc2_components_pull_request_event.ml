module Primary = struct
  module Assignees = struct
    type t = Githubc2_components_simple_user.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Labels = struct
    type t = Githubc2_components_label.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    action : string;
    assignee : Githubc2_components_simple_user.t option; [@default None]
    assignees : Assignees.t option; [@default None]
    label : Githubc2_components_label.t option; [@default None]
    labels : Labels.t option; [@default None]
    number : int;
    pull_request : Githubc2_components_pull_request_minimal.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
