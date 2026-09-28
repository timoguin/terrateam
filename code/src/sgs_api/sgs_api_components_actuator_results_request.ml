type t =
  | Actuator_results_preview of Sgs_api_components_actuator_results_preview.t
  | Actuator_results_commit of Sgs_api_components_actuator_results_commit.t
  | Actuator_results_commit_failed of Sgs_api_components_actuator_results_commit_failed.t
  | Actuator_results_chunk of Sgs_api_components_actuator_results_chunk.t
  | Actuator_results_done of Sgs_api_components_actuator_results_done.t
  | Actuator_results_failure of Sgs_api_components_actuator_results_failure.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v ->
         map
           (fun v -> Actuator_results_preview v)
           (Sgs_api_components_actuator_results_preview.of_yojson v));
       (fun v ->
         map
           (fun v -> Actuator_results_commit v)
           (Sgs_api_components_actuator_results_commit.of_yojson v));
       (fun v ->
         map
           (fun v -> Actuator_results_commit_failed v)
           (Sgs_api_components_actuator_results_commit_failed.of_yojson v));
       (fun v ->
         map
           (fun v -> Actuator_results_chunk v)
           (Sgs_api_components_actuator_results_chunk.of_yojson v));
       (fun v ->
         map
           (fun v -> Actuator_results_done v)
           (Sgs_api_components_actuator_results_done.of_yojson v));
       (fun v ->
         map
           (fun v -> Actuator_results_failure v)
           (Sgs_api_components_actuator_results_failure.of_yojson v));
     ])

let to_yojson = function
  | Actuator_results_preview v -> Sgs_api_components_actuator_results_preview.to_yojson v
  | Actuator_results_commit v -> Sgs_api_components_actuator_results_commit.to_yojson v
  | Actuator_results_commit_failed v ->
      Sgs_api_components_actuator_results_commit_failed.to_yojson v
  | Actuator_results_chunk v -> Sgs_api_components_actuator_results_chunk.to_yojson v
  | Actuator_results_done v -> Sgs_api_components_actuator_results_done.to_yojson v
  | Actuator_results_failure v -> Sgs_api_components_actuator_results_failure.to_yojson v
