type t = {
  is_instance_admin : bool;
  is_tenant_admin : bool;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
