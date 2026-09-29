module Tokens = struct
  type t = Sgs_api_components_access_token_summary.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { tokens : Tokens.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
