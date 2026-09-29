module Kind = struct
  let t_of_yojson = function
    | `String "state_schema_behind" -> Ok `State_schema_behind
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `State_schema_behind -> `String "state_schema_behind"

  type t = ([ `State_schema_behind ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module States = struct
  type t = Sgs_actuator_run_result_state_schema_behind_state.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  kind : Kind.t;
  server_schema_version : int;
  states : States.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
