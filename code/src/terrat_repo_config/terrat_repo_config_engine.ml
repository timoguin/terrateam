type t =
  | Engine_cdktf of Terrat_repo_config_engine_cdktf.t
  | Engine_opentofu of Terrat_repo_config_engine_opentofu.t
  | Engine_terraform of Terrat_repo_config_engine_terraform.t
  | Engine_terragrunt of Terrat_repo_config_engine_terragrunt.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v -> map (fun v -> Engine_cdktf v) (Terrat_repo_config_engine_cdktf.of_yojson v));
       (fun v -> map (fun v -> Engine_opentofu v) (Terrat_repo_config_engine_opentofu.of_yojson v));
       (fun v ->
         map (fun v -> Engine_terraform v) (Terrat_repo_config_engine_terraform.of_yojson v));
       (fun v ->
         map (fun v -> Engine_terragrunt v) (Terrat_repo_config_engine_terragrunt.of_yojson v));
     ])

let to_yojson = function
  | Engine_cdktf v -> Terrat_repo_config_engine_cdktf.to_yojson v
  | Engine_opentofu v -> Terrat_repo_config_engine_opentofu.to_yojson v
  | Engine_terraform v -> Terrat_repo_config_engine_terraform.to_yojson v
  | Engine_terragrunt v -> Terrat_repo_config_engine_terragrunt.to_yojson v