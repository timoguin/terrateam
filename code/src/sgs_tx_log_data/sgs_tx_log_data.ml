module Edge = Sgs_tx_log_data_edge
module File_delete = Sgs_tx_log_data_file_delete
module File_set = Sgs_tx_log_data_file_set
module Hcl_delete = Sgs_tx_log_data_hcl_delete
module Hcl_set = Sgs_tx_log_data_hcl_set
module Refresh = Sgs_tx_log_data_refresh
module State_set = Sgs_tx_log_data_state_set
module State_set_check_result = Sgs_tx_log_data_state_set_check_result
module State_set_check_result_entry = Sgs_tx_log_data_state_set_check_result_entry
module State_set_instance = Sgs_tx_log_data_state_set_instance
module State_set_output = Sgs_tx_log_data_state_set_output
module State_set_provider = Sgs_tx_log_data_state_set_provider
module State_set_resource = Sgs_tx_log_data_state_set_resource
module State_set_state_metadata = Sgs_tx_log_data_state_set_state_metadata
module Tfvar_delete = Sgs_tx_log_data_tfvar_delete
module Tfvar_ephemeral = Sgs_tx_log_data_tfvar_ephemeral
module Tfvar_set = Sgs_tx_log_data_tfvar_set
module Tx_log_data = Sgs_tx_log_data_tx_log_data

module Event = struct
  type t = Tx_log_data of Sgs_tx_log_data_tx_log_data.t [@@deriving show, eq]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
       [ (fun v -> map (fun v -> Tx_log_data v) (Sgs_tx_log_data_tx_log_data.of_yojson v)) ])

  let to_yojson = function
    | Tx_log_data v -> Sgs_tx_log_data_tx_log_data.to_yojson v
end
