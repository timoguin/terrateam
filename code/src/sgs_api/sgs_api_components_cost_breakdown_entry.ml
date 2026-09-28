type t = {
  hourly_cost : string option; [@default None]
  monthly_cost : string option; [@default None]
  name : string;
  resource_count : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
