module Findings_added = struct
  type t = Sgs_api_components_security_finding.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Findings_resolved = struct
  type t = Sgs_api_components_security_finding.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Scan_ids = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Source = struct
  let t_of_yojson = function
    | `String "commit" -> Ok `Commit
    | `String "planned" -> Ok `Planned
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Commit -> `String "commit"
    | `Planned -> `String "planned"

  type t =
    ([ `Commit
     | `Planned
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module States_affected = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  computed_at : string;
  cross_boundary_finding_count : int;
  findings_added : Findings_added.t;
  findings_resolved : Findings_resolved.t;
  scan_ids : Scan_ids.t;
  source : Source.t;
  states_affected : States_affected.t;
  tx_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
