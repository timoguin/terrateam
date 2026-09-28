module Entries = struct
  type t = Sgs_api_components_cost_breakdown_entry_delta.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  entries : Entries.t;
  tag_key : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
