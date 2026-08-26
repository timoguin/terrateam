type t = { tenants : Sgs_session_caps_tenants.t option [@default None] }
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
