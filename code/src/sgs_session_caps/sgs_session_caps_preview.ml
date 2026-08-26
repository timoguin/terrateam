type t = {
  states : Sgs_session_caps_states.t option; [@default None]
  subgraph : Sgs_session_caps_states.t option; [@default None]
  tenants : Sgs_session_caps_tenants.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
