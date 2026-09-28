type t = {
  address : string;
  change_kind : string;
  current_hourly_cost : string option; [@default None]
  current_monthly_cost : string option; [@default None]
  delta_hourly_cost : string option; [@default None]
  delta_monthly_cost : string option; [@default None]
  planned_hourly_cost : string option; [@default None]
  planned_monthly_cost : string option; [@default None]
  provider : string option; [@default None]
  region : string option; [@default None]
  type_ : string; [@key "type"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
