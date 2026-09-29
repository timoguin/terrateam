module Events = struct
  type t = Sgs_api_components_dedicated_stategraph_event.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  created_at : string;
  events : Events.t option; [@default None]
  failure_reason : string option; [@default None]
  fqdn : string option; [@default None]
  id : string;
  name : string;
  region : string option; [@default None]
  slug : string;
  status : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
