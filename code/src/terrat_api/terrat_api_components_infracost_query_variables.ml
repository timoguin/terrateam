type t = {
  pricefilter : Terrat_api_components_infracost_price_filter.t option;
      [@default None] [@key "priceFilter"]
  productfilter : Terrat_api_components_infracost_product_filter.t option;
      [@default None] [@key "productFilter"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
