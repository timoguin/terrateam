type t = {
  calculated_at : string option; [@default None]
  coverage_percent : float option; [@default None]
  hourly_cost : string option; [@default None]
  monthly_cost : string option; [@default None]
  resource_count : int option; [@default None]
  state_id : string;
  state_name : string;
  supported_count : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
