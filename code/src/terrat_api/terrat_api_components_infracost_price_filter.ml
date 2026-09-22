type t = {
  description : string option; [@default None]
  description_regex : string option; [@default None]
  endusageamount : string option; [@default None] [@key "endUsageAmount"]
  purchaseoption : string option; [@default None] [@key "purchaseOption"]
  startusageamount : string option; [@default None] [@key "startUsageAmount"]
  termlength : string option; [@default None] [@key "termLength"]
  termofferingclass : string option; [@default None] [@key "termOfferingClass"]
  termpurchaseoption : string option; [@default None] [@key "termPurchaseOption"]
  unit : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
