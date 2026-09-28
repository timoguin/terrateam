type t = {
  billed_cost : string;
  currency : string option; [@default None]
  line_count : int;
  provider : string;
  region_id : string option; [@default None]
  resource_id : string;
  resource_type : string option; [@default None]
  service_name : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
