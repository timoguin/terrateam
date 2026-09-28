type t = {
  created_at : string;
  enabled : bool;
  id : string;
  last_error : string option; [@default None]
  last_row_count : int option; [@default None]
  last_status : string option; [@default None]
  last_synced_at : string option; [@default None]
  provider : string;
  region : string option; [@default None]
  source_uri : string;
  tenant_id : string;
  updated_at : string;
  window_months : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
