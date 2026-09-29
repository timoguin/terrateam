type t =
  | State_set_state_metadata of Sgs_tx_log_data_state_set_state_metadata.t
  | State_set_output of Sgs_tx_log_data_state_set_output.t
  | State_set_provider of Sgs_tx_log_data_state_set_provider.t
  | State_set_resource of Sgs_tx_log_data_state_set_resource.t
  | State_set_instance of Sgs_tx_log_data_state_set_instance.t
  | State_set_check_result of Sgs_tx_log_data_state_set_check_result.t
  | State_set_check_result_entry of Sgs_tx_log_data_state_set_check_result_entry.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v ->
         map
           (fun v -> State_set_state_metadata v)
           (Sgs_tx_log_data_state_set_state_metadata.of_yojson v));
       (fun v -> map (fun v -> State_set_output v) (Sgs_tx_log_data_state_set_output.of_yojson v));
       (fun v ->
         map (fun v -> State_set_provider v) (Sgs_tx_log_data_state_set_provider.of_yojson v));
       (fun v ->
         map (fun v -> State_set_resource v) (Sgs_tx_log_data_state_set_resource.of_yojson v));
       (fun v ->
         map (fun v -> State_set_instance v) (Sgs_tx_log_data_state_set_instance.of_yojson v));
       (fun v ->
         map
           (fun v -> State_set_check_result v)
           (Sgs_tx_log_data_state_set_check_result.of_yojson v));
       (fun v ->
         map
           (fun v -> State_set_check_result_entry v)
           (Sgs_tx_log_data_state_set_check_result_entry.of_yojson v));
     ])

let to_yojson = function
  | State_set_state_metadata v -> Sgs_tx_log_data_state_set_state_metadata.to_yojson v
  | State_set_output v -> Sgs_tx_log_data_state_set_output.to_yojson v
  | State_set_provider v -> Sgs_tx_log_data_state_set_provider.to_yojson v
  | State_set_resource v -> Sgs_tx_log_data_state_set_resource.to_yojson v
  | State_set_instance v -> Sgs_tx_log_data_state_set_instance.to_yojson v
  | State_set_check_result v -> Sgs_tx_log_data_state_set_check_result.to_yojson v
  | State_set_check_result_entry v -> Sgs_tx_log_data_state_set_check_result_entry.to_yojson v
