module Instance_costs = struct
  type t = Sgs_api_components_instance_cost.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  calculated_at : string;
  coverage_percent : float;
  currency : string;
  hourly_cost : string option; [@default None]
  instance_costs : Instance_costs.t;
  monthly_cost : string option; [@default None]
  priced_count : int;
  resource_count : int;
  snapshot_id : string;
  source : string;
  supported_count : int;
  triggered_by : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
