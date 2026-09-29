type t =
  | Run_success_preview of Sgs_actuator_run_result_run_success_preview.t
  | Run_success_commit of Sgs_actuator_run_result_run_success_commit.t
  | Run_failure of Sgs_actuator_run_result_run_failure.t
  | Run_success_noop of Sgs_actuator_run_result_run_success_noop.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v ->
         map
           (fun v -> Run_success_preview v)
           (Sgs_actuator_run_result_run_success_preview.of_yojson v));
       (fun v ->
         map
           (fun v -> Run_success_commit v)
           (Sgs_actuator_run_result_run_success_commit.of_yojson v));
       (fun v -> map (fun v -> Run_failure v) (Sgs_actuator_run_result_run_failure.of_yojson v));
       (fun v ->
         map (fun v -> Run_success_noop v) (Sgs_actuator_run_result_run_success_noop.of_yojson v));
     ])

let to_yojson = function
  | Run_success_preview v -> Sgs_actuator_run_result_run_success_preview.to_yojson v
  | Run_success_commit v -> Sgs_actuator_run_result_run_success_commit.to_yojson v
  | Run_failure v -> Sgs_actuator_run_result_run_failure.to_yojson v
  | Run_success_noop v -> Sgs_actuator_run_result_run_success_noop.to_yojson v
