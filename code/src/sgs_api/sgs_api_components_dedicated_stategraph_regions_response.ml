module Regions = struct
  type t = Sgs_api_components_dedicated_stategraph_region.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { regions : Regions.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
