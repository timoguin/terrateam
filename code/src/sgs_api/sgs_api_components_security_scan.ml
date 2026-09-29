module Kind = struct
  let t_of_yojson = function
    | `String "current" -> Ok `Current
    | `String "planned" -> Ok `Planned
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Current -> `String "current"
    | `Planned -> `String "planned"

  type t =
    ([ `Current
     | `Planned
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Severity_breakdown = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Status = struct
  let t_of_yojson = function
    | `String "completed" -> Ok `Completed
    | `String "failed" -> Ok `Failed
    | `String "running" -> Ok `Running
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Completed -> `String "completed"
    | `Failed -> `String "failed"
    | `Running -> `String "running"

  type t =
    ([ `Completed
     | `Failed
     | `Running
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  error_message : string option; [@default None]
  finding_count : int;
  id : string;
  kind : Kind.t;
  scanned_at : string;
  scanner : string;
  scanner_version : string option; [@default None]
  severity_breakdown : Severity_breakdown.t option; [@default None]
  state_id : string;
  status : Status.t;
  triggered_by : string;
  tx_id : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
