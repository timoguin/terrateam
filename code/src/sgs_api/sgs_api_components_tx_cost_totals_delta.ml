type t = {
  currency : string option; [@default None]
  current_coverage_percent : float;
  current_hourly_cost : string option; [@default None]
  current_monthly_cost : string option; [@default None]
  current_priced_count : int;
  current_resource_count : int;
  current_supported_count : int;
  delta_coverage_percent : float;
  delta_hourly_cost : string option; [@default None]
  delta_monthly_cost : string option; [@default None]
  delta_priced_count : int;
  delta_resource_count : int;
  delta_supported_count : int;
  planned_coverage_percent : float;
  planned_hourly_cost : string option; [@default None]
  planned_monthly_cost : string option; [@default None]
  planned_priced_count : int;
  planned_resource_count : int;
  planned_supported_count : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
