module Access_token_create = Sgs_session_caps_access_token_create
module Access_token_refresh = Sgs_session_caps_access_token_refresh
module Admin = Sgs_session_caps_admin
module Capabilities = Sgs_session_caps_capabilities
module Commit = Sgs_session_caps_commit
module Preview = Sgs_session_caps_preview
module States = Sgs_session_caps_states
module Sudo = Sgs_session_caps_sudo
module Tenants = Sgs_session_caps_tenants
module Users_manage = Sgs_session_caps_users_manage

module Event = struct
  type t = Capabilities of Sgs_session_caps_capabilities.t [@@deriving show, eq]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
       [ (fun v -> map (fun v -> Capabilities v) (Sgs_session_caps_capabilities.of_yojson v)) ])

  let to_yojson = function
    | Capabilities v -> Sgs_session_caps_capabilities.to_yojson v
end
