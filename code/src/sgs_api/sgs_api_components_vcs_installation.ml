type t = {
  created_at : string;
  installation_core_id : string;
  provider : string;
  tenant_id : string;
  updated_at : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
