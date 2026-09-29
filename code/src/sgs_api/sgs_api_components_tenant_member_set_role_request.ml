type t = {
  can_manage_users : bool option; [@default None]
  tenant_admin : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
