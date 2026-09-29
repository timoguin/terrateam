module Reason = Sgs_capability_denied_reason
module Reason_capability = Sgs_capability_denied_reason_capability
module Reason_resource = Sgs_capability_denied_reason_resource
module Reason_state = Sgs_capability_denied_reason_state
module Reason_subgraph = Sgs_capability_denied_reason_subgraph
module Reason_tenant = Sgs_capability_denied_reason_tenant
module Response = Sgs_capability_denied_response

module Event = struct
  type t = Response of Sgs_capability_denied_response.t [@@deriving show, eq]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
       [ (fun v -> map (fun v -> Response v) (Sgs_capability_denied_response.of_yojson v)) ])

  let to_yojson = function
    | Response v -> Sgs_capability_denied_response.to_yojson v
end
