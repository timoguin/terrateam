module By_provider = struct
  type t = Sgs_api_components_cost_breakdown_entry_delta.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module By_tag = struct
  type t = Sgs_api_components_tx_cost_tag_breakdown_delta.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module By_type = struct
  type t = Sgs_api_components_cost_breakdown_entry_delta.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module States = struct
  type t = Sgs_api_components_tx_cost_state_delta.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  by_provider : By_provider.t;
  by_tag : By_tag.t;
  by_type : By_type.t;
  states : States.t;
  totals : Sgs_api_components_tx_cost_totals_delta.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
