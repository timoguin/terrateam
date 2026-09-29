module By_provider = struct
  type t = Sgs_api_components_cost_breakdown_entry.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module By_tag = struct
  type t = Sgs_api_components_cost_breakdown_entry.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module By_type = struct
  type t = Sgs_api_components_cost_breakdown_entry.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module States = struct
  type t = Sgs_api_components_tenant_cost_state.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  by_provider : By_provider.t;
  by_tag : By_tag.t;
  by_type : By_type.t;
  coverage_percent : float;
  currency : string option; [@default None]
  hourly_cost : string option; [@default None]
  monthly_cost : string option; [@default None]
  priced_count : int;
  resource_count : int;
  states : States.t;
  supported_count : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
