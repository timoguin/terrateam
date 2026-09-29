module Resources = struct
  type t = Sgs_api_components_state_cost_unsupported_resource.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  calculated_at : string;
  resources : Resources.t;
  snapshot_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
