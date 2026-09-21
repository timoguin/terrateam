module Actions = Sg_caps_wire_actions
module Capabilities = Sg_caps_wire_capabilities
module Reach = Sg_caps_wire_reach
module Scope = Sg_caps_wire_scope
module State_reach = Sg_caps_wire_state_reach
module Tenant_reach = Sg_caps_wire_tenant_reach

module Event = struct
  type t = Capabilities of Sg_caps_wire_capabilities.t [@@deriving show, eq]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
       [ (fun v -> map (fun v -> Capabilities v) (Sg_caps_wire_capabilities.of_yojson v)) ])

  let to_yojson = function
    | Capabilities v -> Sg_caps_wire_capabilities.to_yojson v
end
