module Aws_config = struct
  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
end

module Aws_config_warnings = struct
  module Items = struct
    include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Unmanaged_resources = struct
  type t = Sgs_api_components_unmanaged_resource.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  aws_config : Aws_config.t option; [@default None]
  aws_config_warnings : Aws_config_warnings.t option; [@default None]
  fetched_at : float option; [@default None]
  from_cache : bool option; [@default None]
  summary : Sgs_api_components_gap_analysis_summary.t;
  unmanaged_resources : Unmanaged_resources.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
