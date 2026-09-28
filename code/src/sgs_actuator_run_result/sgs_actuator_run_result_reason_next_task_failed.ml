module Kind = struct
  let t_of_yojson = function
    | `String "next_task_failed" -> Ok `Next_task_failed
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Next_task_failed -> `String "next_task_failed"

  type t = ([ `Next_task_failed ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  kind : Kind.t;
  state : Sgs_actuator_run_result_task_state.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
