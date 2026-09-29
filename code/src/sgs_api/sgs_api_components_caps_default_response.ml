type t = { capabilities : Sg_caps_wire_capabilities.t }
[@@deriving yojson { strict = false; meta = true }, show, eq]
