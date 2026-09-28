type t =
  | Gap_analysis_config_response_aws of Sgs_api_components_gap_analysis_config_response_aws.t
  | Gap_analysis_config_response_gcp of Sgs_api_components_gap_analysis_config_response_gcp.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v ->
         map
           (fun v -> Gap_analysis_config_response_aws v)
           (Sgs_api_components_gap_analysis_config_response_aws.of_yojson v));
       (fun v ->
         map
           (fun v -> Gap_analysis_config_response_gcp v)
           (Sgs_api_components_gap_analysis_config_response_gcp.of_yojson v));
     ])

let to_yojson = function
  | Gap_analysis_config_response_aws v ->
      Sgs_api_components_gap_analysis_config_response_aws.to_yojson v
  | Gap_analysis_config_response_gcp v ->
      Sgs_api_components_gap_analysis_config_response_gcp.to_yojson v
