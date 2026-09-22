module Prices = struct
  type t = Terrat_api_components_infracost_price.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { prices : Prices.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
