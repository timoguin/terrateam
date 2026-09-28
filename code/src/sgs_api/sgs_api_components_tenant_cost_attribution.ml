module By_provider = struct
  type t = Sgs_api_components_tenant_cost_attribution_provider.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  attributed_cost : string;
  attributed_count : int;
  by_provider : By_provider.t;
  computed_at : string option; [@default None]
  coverage_percent : float;
  currency : string option; [@default None]
  line_count : int;
  matcher_version : int option; [@default None]
  total_cost : string;
  unallocated_cost : string;
  unallocated_count : int;
  uncomputed_count : int;
  unmanaged_cost : string;
  unmanaged_count : int;
  window_end : string option; [@default None]
  window_start : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
