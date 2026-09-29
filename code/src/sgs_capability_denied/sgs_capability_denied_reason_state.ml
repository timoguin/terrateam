module Kind = struct
  let t_of_yojson = function
    | `String "state" -> Ok `State
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `State -> `String "state"

  type t = ([ `State ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  kind : Kind.t;
  state_id : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
