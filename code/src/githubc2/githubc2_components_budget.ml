module Primary = struct
  module Budget_alerting = struct
    module Primary = struct
      module Alert_recipients = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        alert_recipients : Alert_recipients.t;
        will_alert : bool;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Budget_scope = struct
    let t_of_yojson = function
      | `String "cost_center" -> Ok `Cost_center
      | `String "enterprise" -> Ok `Enterprise
      | `String "multi_user_cost_center" -> Ok `Multi_user_cost_center
      | `String "multi_user_customer" -> Ok `Multi_user_customer
      | `String "organization" -> Ok `Organization
      | `String "repository" -> Ok `Repository
      | `String "user" -> Ok `User
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Cost_center -> `String "cost_center"
      | `Enterprise -> `String "enterprise"
      | `Multi_user_cost_center -> `String "multi_user_cost_center"
      | `Multi_user_customer -> `String "multi_user_customer"
      | `Organization -> `String "organization"
      | `Repository -> `String "repository"
      | `User -> `String "user"

    type t =
      ([ `Cost_center
       | `Enterprise
       | `Multi_user_cost_center
       | `Multi_user_customer
       | `Organization
       | `Repository
       | `User
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Budget_type = struct
    module V0 = struct
      let t_of_yojson = function
        | `String "SkuPricing" -> Ok `SkuPricing
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `SkuPricing -> `String "SkuPricing"

      type t = ([ `SkuPricing ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module V1 = struct
      let t_of_yojson = function
        | `String "ProductPricing" -> Ok `ProductPricing
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `ProductPricing -> `String "ProductPricing"

      type t = ([ `ProductPricing ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t =
      | V0 of V0.t
      | V1 of V1.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
         [
           (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
           (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
         ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
      | V1 v -> V1.to_yojson v
  end

  type t = {
    budget_alerting : Budget_alerting.t;
    budget_amount : int;
    budget_entity_name : string option; [@default None]
    budget_product_sku : string;
    budget_scope : Budget_scope.t;
    budget_type : Budget_type.t;
    consumed_amount : float option; [@default None]
    id : string;
    prevent_further_usage : bool;
    user : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
