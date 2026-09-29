type t =
  | Reason_capability of Sgs_capability_denied_reason_capability.t
  | Reason_tenant of Sgs_capability_denied_reason_tenant.t
  | Reason_state of Sgs_capability_denied_reason_state.t
  | Reason_resource of Sgs_capability_denied_reason_resource.t
  | Reason_subgraph of Sgs_capability_denied_reason_subgraph.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v ->
         map (fun v -> Reason_capability v) (Sgs_capability_denied_reason_capability.of_yojson v));
       (fun v -> map (fun v -> Reason_tenant v) (Sgs_capability_denied_reason_tenant.of_yojson v));
       (fun v -> map (fun v -> Reason_state v) (Sgs_capability_denied_reason_state.of_yojson v));
       (fun v ->
         map (fun v -> Reason_resource v) (Sgs_capability_denied_reason_resource.of_yojson v));
       (fun v ->
         map (fun v -> Reason_subgraph v) (Sgs_capability_denied_reason_subgraph.of_yojson v));
     ])

let to_yojson = function
  | Reason_capability v -> Sgs_capability_denied_reason_capability.to_yojson v
  | Reason_tenant v -> Sgs_capability_denied_reason_tenant.to_yojson v
  | Reason_state v -> Sgs_capability_denied_reason_state.to_yojson v
  | Reason_resource v -> Sgs_capability_denied_reason_resource.to_yojson v
  | Reason_subgraph v -> Sgs_capability_denied_reason_subgraph.to_yojson v
