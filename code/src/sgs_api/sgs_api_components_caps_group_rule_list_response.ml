module Rules = struct
  type t = Sgs_api_components_caps_group_rule.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { rules : Rules.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
