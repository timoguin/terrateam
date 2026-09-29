module Options = struct
  type t = Sgs_api_components_login_option.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { options : Options.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
