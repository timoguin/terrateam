module Kind = struct
  let t_of_yojson = function
    | `String "tx_invalid_state" -> Ok `Tx_invalid_state
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Tx_invalid_state -> `String "tx_invalid_state"

  type t = ([ `Tx_invalid_state ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  actual_state : string option; [@default None]
  expected_state : string;
  kind : Kind.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
