module State_ids = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  share_url : string option; [@default None]
  state_ids : State_ids.t;
  tx : Sgs_api_components_tx.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
