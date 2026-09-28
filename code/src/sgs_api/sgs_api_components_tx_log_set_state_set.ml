type t =
  | Tx_log_set_state_set_state_metadata of Sgs_api_components_tx_log_set_state_set_state_metadata.t
  | Tx_log_set_state_set_output of Sgs_api_components_tx_log_set_state_set_output.t
  | Tx_log_set_state_set_provider of Sgs_api_components_tx_log_set_state_set_provider.t
  | Tx_log_set_state_set_resource of Sgs_api_components_tx_log_set_state_set_resource.t
  | Tx_log_set_state_set_instance of Sgs_api_components_tx_log_set_state_set_instance.t
  | Tx_log_set_state_set_check_result of Sgs_api_components_tx_log_set_state_set_check_result.t
  | Tx_log_set_state_set_check_result_entry of
      Sgs_api_components_tx_log_set_state_set_check_result_entry.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v ->
         map
           (fun v -> Tx_log_set_state_set_state_metadata v)
           (Sgs_api_components_tx_log_set_state_set_state_metadata.of_yojson v));
       (fun v ->
         map
           (fun v -> Tx_log_set_state_set_output v)
           (Sgs_api_components_tx_log_set_state_set_output.of_yojson v));
       (fun v ->
         map
           (fun v -> Tx_log_set_state_set_provider v)
           (Sgs_api_components_tx_log_set_state_set_provider.of_yojson v));
       (fun v ->
         map
           (fun v -> Tx_log_set_state_set_resource v)
           (Sgs_api_components_tx_log_set_state_set_resource.of_yojson v));
       (fun v ->
         map
           (fun v -> Tx_log_set_state_set_instance v)
           (Sgs_api_components_tx_log_set_state_set_instance.of_yojson v));
       (fun v ->
         map
           (fun v -> Tx_log_set_state_set_check_result v)
           (Sgs_api_components_tx_log_set_state_set_check_result.of_yojson v));
       (fun v ->
         map
           (fun v -> Tx_log_set_state_set_check_result_entry v)
           (Sgs_api_components_tx_log_set_state_set_check_result_entry.of_yojson v));
     ])

let to_yojson = function
  | Tx_log_set_state_set_state_metadata v ->
      Sgs_api_components_tx_log_set_state_set_state_metadata.to_yojson v
  | Tx_log_set_state_set_output v -> Sgs_api_components_tx_log_set_state_set_output.to_yojson v
  | Tx_log_set_state_set_provider v -> Sgs_api_components_tx_log_set_state_set_provider.to_yojson v
  | Tx_log_set_state_set_resource v -> Sgs_api_components_tx_log_set_state_set_resource.to_yojson v
  | Tx_log_set_state_set_instance v -> Sgs_api_components_tx_log_set_state_set_instance.to_yojson v
  | Tx_log_set_state_set_check_result v ->
      Sgs_api_components_tx_log_set_state_set_check_result.to_yojson v
  | Tx_log_set_state_set_check_result_entry v ->
      Sgs_api_components_tx_log_set_state_set_check_result_entry.to_yojson v
