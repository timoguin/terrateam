module Resources = struct
  type t = Sgs_api_components_tx_cost_resource_delta.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  current_hourly_cost : string option; [@default None]
  current_monthly_cost : string option; [@default None]
  current_resource_count : int option; [@default None]
  delta_hourly_cost : string option; [@default None]
  delta_monthly_cost : string option; [@default None]
  delta_resource_count : int;
  planned_hourly_cost : string option; [@default None]
  planned_monthly_cost : string option; [@default None]
  planned_resource_count : int option; [@default None]
  resources : Resources.t;
  state_id : string;
  state_name : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
