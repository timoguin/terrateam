type t = {
  idx : int;
  request : Sgs_api_components_actuator_results_request.t;
  task_id : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
