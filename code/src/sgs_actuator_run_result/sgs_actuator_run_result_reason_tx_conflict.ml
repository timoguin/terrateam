module Conflicting_tx_ids = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Kind = struct
  let t_of_yojson = function
    | `String "tx_conflict" -> Ok `Tx_conflict
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Tx_conflict -> `String "tx_conflict"

  type t = ([ `Tx_conflict ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  conflicting_tx_ids : Conflicting_tx_ids.t;
  kind : Kind.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
