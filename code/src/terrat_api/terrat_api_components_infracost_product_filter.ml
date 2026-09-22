module AttributeFilters = struct
  type t = Terrat_api_components_infracost_attribute_filter.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  attributefilters : AttributeFilters.t option; [@default None] [@key "attributeFilters"]
  productfamily : string option; [@default None] [@key "productFamily"]
  region : string option; [@default None]
  service : string option; [@default None]
  sku : string option; [@default None]
  vendorname : string option; [@default None] [@key "vendorName"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
