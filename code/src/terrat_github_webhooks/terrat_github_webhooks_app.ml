module Events = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Permissions = struct
  module Additional = struct
    type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
end

type t = {
  created_at : string option; [@default None]
  description : string option; [@default None]
  events : Events.t option; [@default None]
  external_url : string option; [@default None]
  html_url : string option; [@default None]
  id : int option; [@default None]
  name : string option; [@default None]
  node_id : string option; [@default None]
  owner : Terrat_github_webhooks_user.t option; [@default None]
  permissions : Permissions.t option; [@default None]
  slug : string option; [@default None]
  updated_at : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
