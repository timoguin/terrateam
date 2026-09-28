type t = {
  arn : string option; [@default None]
  asset_name : string option; [@default None]
  id : string option; [@default None]
  owning_account_id : string option; [@default None]
  project_id : string option; [@default None]
  provider : string option; [@default None]
  region : string option; [@default None]
  resource_type : string;
  service : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
