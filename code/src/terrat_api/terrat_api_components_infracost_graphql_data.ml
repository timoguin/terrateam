module Products = struct
  type t = Terrat_api_components_infracost_product.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { products : Products.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
