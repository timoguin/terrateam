module Points = struct
  type t = Sgs_api_components_tenant_cost_history_point.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { points : Points.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
