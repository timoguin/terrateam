type t = {
  email : string;
  tenant_admin : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
