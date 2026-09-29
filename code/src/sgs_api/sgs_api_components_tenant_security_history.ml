module Points = struct
  type t = Sgs_api_components_tenant_security_breakdown_entry.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  last_scanned_at : string option; [@default None]
  points : Points.t;
  states_scanned : int;
  states_total : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
