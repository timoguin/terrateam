module Primary = struct
  module Permissions = struct
    module Primary = struct
      type t = {
        admin : bool;
        maintain : bool;
        pull : bool;
        push : bool;
        triage : bool;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    description : string option;
    html_url : string;
    id : int;
    members_url : string;
    name : string;
    node_id : string;
    parent : Githubc2_components_nullable_team_simple.t option;
    permission : string;
    permissions : Permissions.t option; [@default None]
    privacy : string option; [@default None]
    repositories_url : string;
    slug : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)