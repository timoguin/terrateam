type t = {
  capabilities : Sg_caps_wire_capabilities.t option; [@default None]
  name : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
