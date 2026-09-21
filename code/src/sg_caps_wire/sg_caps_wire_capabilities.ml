type t = {
  access_token_create : bool; [@key "access-token-create"]
  access_token_refresh : bool; [@key "access-token-refresh"]
  admin : Sg_caps_wire_scope.t;
  commit : Sg_caps_wire_actions.t;
  preview : Sg_caps_wire_actions.t;
  sudo : Sg_caps_wire_scope.t;
  users_manage : Sg_caps_wire_scope.t; [@key "users-manage"]
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
