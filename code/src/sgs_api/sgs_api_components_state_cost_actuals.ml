module Resources = struct
  type t = Sgs_api_components_state_cost_actual_resource.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  billed_cost : string;
  computed_at : string option; [@default None]
  currency : string option; [@default None]
  line_count : int;
  resources : Resources.t;
  window_end : string option; [@default None]
  window_start : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
