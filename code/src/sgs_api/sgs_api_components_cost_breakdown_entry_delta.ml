type t = {
  current_hourly_cost : string option; [@default None]
  current_monthly_cost : string option; [@default None]
  current_resource_count : int option; [@default None]
  delta_hourly_cost : string option; [@default None]
  delta_monthly_cost : string option; [@default None]
  delta_resource_count : int;
  name : string;
  planned_hourly_cost : string option; [@default None]
  planned_monthly_cost : string option; [@default None]
  planned_resource_count : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
