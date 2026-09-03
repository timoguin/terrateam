module Primary = struct
  module Allowed_actors = struct
    type t = Githubc2_components_repository_rule_params_actor.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    allowed_actors : Allowed_actors.t option; [@default None]
    enabled : bool;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
