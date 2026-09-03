module Primary = struct
  module Custom_pattern_overrides = struct
    type t = Githubc2_components_secret_scanning_pattern_override.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Provider_pattern_overrides = struct
    type t = Githubc2_components_secret_scanning_pattern_override.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    custom_pattern_overrides : Custom_pattern_overrides.t option; [@default None]
    pattern_config_version : string option; [@default None]
    provider_pattern_overrides : Provider_pattern_overrides.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
