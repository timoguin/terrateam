module State_names = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Tags = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  completed_at : string option; [@default None]
  completed_by : string option; [@default None]
  created_at : string;
  created_by : string;
  created_by_name : string option; [@default None]
  id : string;
  params : Sgs_api_components_tx_params.t;
  plan_summary : Sgs_api_components_plan_summary.t option; [@default None]
  state : string;
  state_names : State_names.t option; [@default None]
  tags : Tags.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
