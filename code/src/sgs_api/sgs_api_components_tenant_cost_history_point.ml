module Groups = struct
  type t = Sgs_api_components_cost_breakdown_entry.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  date : string;
  groups : Groups.t;
  hourly_cost : string option; [@default None]
  monthly_cost : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
