type t = {
  name : string;
  tenant_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
