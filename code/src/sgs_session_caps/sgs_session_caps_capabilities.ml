type t = {
  access_token_create : bool option; [@key "access-token-create"] [@default None]
  access_token_refresh : bool option; [@key "access-token-refresh"] [@default None]
  admin : Sgs_session_caps_admin.t option; [@default None]
  commit : Sgs_session_caps_commit.t option; [@default None]
  preview : Sgs_session_caps_preview.t option; [@default None]
  sudo : Sgs_session_caps_sudo.t option; [@default None]
  users_manage : Sgs_session_caps_users_manage.t option; [@key "users-manage"] [@default None]
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
