module Kind = struct
  let t_of_yojson = function
    | `String "success_noop" -> Ok `Success_noop
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Success_noop -> `String "success_noop"

  type t = ([ `Success_noop ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Reason = struct
  let t_of_yojson = function
    | `String "no_data_sources" -> Ok `No_data_sources
    | `String "refresh_skipped" -> Ok `Refresh_skipped
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `No_data_sources -> `String "no_data_sources"
    | `Refresh_skipped -> `String "refresh_skipped"

  type t =
    ([ `No_data_sources
     | `Refresh_skipped
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  kind : Kind.t;
  reason : Reason.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
