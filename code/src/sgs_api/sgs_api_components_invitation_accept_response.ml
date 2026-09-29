type t = {
  already_member : bool;
  email_mismatch : bool;
  tenant_id : string;
  tenant_name : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
