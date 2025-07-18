type t = {
  attachment : string option; [@default None]
  author : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  body : string option; [@default None]
  commands_changes : string option; [@default None]
  commit_id : string option; [@default None]
  confidential : string option; [@default None]
  created_at : string option; [@default None]
  id : string option; [@default None]
  imported : string option; [@default None]
  imported_from : string option; [@default None]
  internal : string option; [@default None]
  noteable_id : string option; [@default None]
  noteable_iid : string option; [@default None]
  noteable_type : string option; [@default None]
  position : string option; [@default None]
  project_id : string option; [@default None]
  resolvable : string option; [@default None]
  resolved : string option; [@default None]
  resolved_at : string option; [@default None]
  resolved_by : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  system : string option; [@default None]
  type_ : string option; [@default None] [@key "type"]
  updated_at : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
