module Primary = struct
  module TimePeriod = struct
    module Primary = struct
      type t = {
        day : int option; [@default None]
        month : int option; [@default None]
        year : int;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module UsageItems = struct
    module Items = struct
      module Primary = struct
        type t = {
          discountamount : float; [@key "discountAmount"]
          discountquantity : float; [@key "discountQuantity"]
          grossamount : float; [@key "grossAmount"]
          grossquantity : float; [@key "grossQuantity"]
          model : string;
          netamount : float; [@key "netAmount"]
          netquantity : float; [@key "netQuantity"]
          priceperunit : float; [@key "pricePerUnit"]
          product : string;
          sku : string;
          unittype : string; [@key "unitType"]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    model : string option; [@default None]
    organization : string;
    product : string option; [@default None]
    timeperiod : TimePeriod.t; [@key "timePeriod"]
    usageitems : UsageItems.t; [@key "usageItems"]
    user : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
