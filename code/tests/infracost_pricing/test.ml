module Ip = Infracost_pricing

module Decoded = struct
  type t = (Ip.Element.t list, Ip.err) result [@@deriving show, eq]
end

let encode element rows =
  Terrat_api_components.Infracost_graphql_response.to_yojson (Ip.Tests.encode element rows)

let query_text currency =
  Printf.sprintf
    {|
		query($productFilter: ProductFilter!, $priceFilter: PriceFilter) {
			products(filter: $productFilter) {
				prices(filter: $priceFilter) {
					priceHash
					%s
				}
			}
		}
	|}
    currency

let batch elements = `List elements

let query_element ?(currency = "USD") ?product_filter ?price_filter () =
  `Assoc
    ([ ("query", `String (query_text currency)) ]
    @
    match (product_filter, price_filter) with
    | None, None -> []
    | product_filter, price_filter ->
        [
          ( "variables",
            `Assoc
              (CCList.filter_map
                 CCFun.id
                 [
                   CCOption.map (fun f -> ("productFilter", f)) product_filter;
                   CCOption.map (fun f -> ("priceFilter", f)) price_filter;
                 ]) );
        ])

let probe_element = `Assoc [ ("query", `String ""); ("variables", `Null) ]

let empty_filter =
  {
    Ip.Filter.vendor_name = None;
    service = None;
    product_family = None;
    region = None;
    sku = None;
    attribute_filters = [];
    purchase_option = None;
    unit = None;
    description = None;
    description_regex = None;
    start_usage_amount = None;
    end_usage_amount = None;
    term_length = None;
    term_purchase_option = None;
    term_offering_class = None;
    currency = "USD";
    rate = "1";
  }

let row
    ?(cny_merge = Ip.Tests.Row.No_cny_merge)
    ?amount
    ?cny_amount
    ?start_usage_amount
    ?end_usage_amount
    ~product_hash
    ~price_hash
    () =
  {
    Ip.Tests.Row.product_hash;
    price_hash = Some price_hash;
    amount;
    cny_amount;
    start_usage_amount;
    end_usage_amount;
    cny_merge;
  }

let assert_prices ~expected filter rows =
  Oth.Assert.Eq.string
    ~expected:(Yojson.Safe.to_string expected)
    ~actual:(Yojson.Safe.to_string (encode (Ip.Element.Query filter) rows))

let products prices =
  `Assoc
    [
      ( "data",
        `Assoc
          [
            ( "products",
              `List
                (CCList.map
                   (fun product ->
                     `Assoc
                       [
                         ( "prices",
                           `List
                             (CCList.map
                                (fun (price_hash, amount) ->
                                  `Assoc
                                    [
                                      ("priceHash", `String price_hash);
                                      ( "USD",
                                        match amount with
                                        | Some amount -> `String amount
                                        | None -> `Null );
                                    ])
                                product) );
                       ])
                   prices) );
          ] );
    ]

let assert_decoded ~expected actual =
  Oth.Assert.eq ~eq:Decoded.equal ~pp:Decoded.pp expected (Ip.decode actual)

let assert_json ~expected actual =
  Oth.Assert.Eq.string
    ~expected:(Yojson.Safe.to_string expected)
    ~actual:(Yojson.Safe.to_string actual)

let decode_one json =
  match Oth.Assert.ok_pp ~pp:Ip.pp_err (Ip.decode (batch [ json ])) with
  | [ element ] -> element
  | _ :: _ | [] -> Oth.Assert.false_ "expected one element"

let filter_of json =
  match decode_one json with
  | Ip.Element.Query filter -> filter
  | Ip.Element.Probe -> Oth.Assert.false_ "expected a query"

let test =
  Oth.parallel
    [
      Oth.test ~name:"decode: the probe" (fun _ ->
          assert_decoded ~expected:(Ok [ Ip.Element.Probe ]) (batch [ probe_element ]);
          ());
      Oth.test ~name:"decode: an empty batch" (fun _ ->
          assert_decoded ~expected:(Ok []) (batch []);
          ());
      Oth.test ~name:"decode: a query with no variables" (fun _ ->
          assert_decoded
            ~expected:(Ok [ Ip.Element.Query empty_filter ])
            (batch [ query_element () ]);
          ());
      Oth.test ~name:"decode: a body that is not an array" (fun _ ->
          assert_decoded ~expected:(Error `Bad_request_err) (query_element ());
          ());
      Oth.test ~name:"decode: a query of a different shape" (fun _ ->
          assert_decoded
            ~expected:(Error `Bad_request_err)
            (batch [ `Assoc [ ("query", `String "query { products { sku } }") ] ]);
          ());
      Oth.test ~name:"decode: a price field that is not a currency code" (fun _ ->
          assert_decoded
            ~expected:(Error `Bad_request_err)
            (batch [ query_element ~currency:"usd" () ]);
          ());
      Oth.test ~name:"decode: an element that is not an object" (fun _ ->
          assert_decoded ~expected:(Error `Bad_request_err) (batch [ `String "nope" ]);
          ());
      Oth.test ~name:"decode: the rate of the currency" (fun _ ->
          let filter = filter_of (query_element ~currency:"EUR" ()) in
          Oth.Assert.Eq.string ~expected:"EUR" ~actual:filter.Ip.Filter.currency;
          Oth.Assert.Eq.string ~expected:"0.853994" ~actual:filter.Ip.Filter.rate;
          ());
      Oth.test ~name:"decode: a currency with no rate" (fun _ ->
          assert_decoded
            ~expected:(Error `Unsupported_currency_err)
            (batch [ query_element ~currency:"XYZ" () ]);
          ());
      Oth.test ~name:"decode: the product filter" (fun _ ->
          let filter =
            filter_of
              (query_element
                 ~product_filter:
                   (`Assoc
                      [
                        ("vendorName", `String "aws");
                        ("service", `String "AmazonEC2");
                        ("productFamily", `String "Compute Instance");
                        ("region", `String "us-east-1");
                        ("sku", `String "ABC123");
                      ])
                 ())
          in
          Oth.Assert.eq
            ~eq:Ip.Filter.equal
            ~pp:Ip.Filter.pp
            {
              empty_filter with
              Ip.Filter.vendor_name = Some "aws";
              service = Some "AmazonEC2";
              product_family = Some "Compute Instance";
              region = Some "us-east-1";
              sku = Some "ABC123";
            }
            filter;
          ());
      Oth.test ~name:"decode: the price filter" (fun _ ->
          let filter =
            filter_of
              (query_element
                 ~price_filter:
                   (`Assoc
                      [
                        ("purchaseOption", `String "on_demand");
                        ("unit", `String "Hrs");
                        ("description", `String "per hour");
                        ("description_regex", `String "/on demand/i");
                        ("startUsageAmount", `String "0");
                        ("endUsageAmount", `String "");
                        ("termLength", `String "1yr");
                        ("termPurchaseOption", `String "All Upfront");
                        ("termOfferingClass", `String "standard");
                      ])
                 ())
          in
          Oth.Assert.eq
            ~eq:Ip.Filter.equal
            ~pp:Ip.Filter.pp
            {
              empty_filter with
              Ip.Filter.purchase_option = Some "on_demand";
              unit = Some "Hrs";
              description = Some "per hour";
              description_regex =
                Some { Ip.Regex.pattern = "on demand"; case = Ip.Regex.Insensitive };
              start_usage_amount = Some "0";
              end_usage_amount = Some "";
              term_length = Some "1yr";
              term_purchase_option = Some "All Upfront";
              term_offering_class = Some "standard";
            }
            filter;
          ());
      Oth.test ~name:"decode: the attribute filters" (fun _ ->
          let filter =
            filter_of
              (query_element
                 ~product_filter:
                   (`Assoc
                      [
                        ( "attributeFilters",
                          `List
                            [
                              `Assoc
                                [ ("key", `String "instanceType"); ("value", `String "t3.micro") ];
                              `Assoc [ ("key", `String "preInstalledSw"); ("value", `String "") ];
                              `Assoc
                                [
                                  ("key", `String "usagetype"); ("value_regex", `String "/BoxUsage/");
                                ];
                              `Assoc
                                [
                                  ("key", `String "operatingSystem");
                                  ("value_regex", `String "/linux/i");
                                ];
                              `Assoc [ ("key", `String "orphan") ];
                            ] );
                      ])
                 ())
          in
          Oth.Assert.eq
            ~eq:(CCList.equal Ip.Attribute_filter.equal)
            ~pp:(CCList.pp Ip.Attribute_filter.pp)
            [
              {
                Ip.Attribute_filter.key = "instanceType";
                match_ = Ip.Attribute_filter.Eq "t3.micro";
              };
              { Ip.Attribute_filter.key = "preInstalledSw"; match_ = Ip.Attribute_filter.Empty };
              {
                Ip.Attribute_filter.key = "usagetype";
                match_ =
                  Ip.Attribute_filter.Regex
                    { Ip.Regex.pattern = "BoxUsage"; case = Ip.Regex.Sensitive };
              };
              {
                Ip.Attribute_filter.key = "operatingSystem";
                match_ =
                  Ip.Attribute_filter.Regex
                    { Ip.Regex.pattern = "linux"; case = Ip.Regex.Insensitive };
              };
              { Ip.Attribute_filter.key = "orphan"; match_ = Ip.Attribute_filter.Never };
            ]
            filter.Ip.Filter.attribute_filters;
          ());
      Oth.test ~name:"decode: an empty value_regex falls back to the value" (fun _ ->
          let filter =
            filter_of
              (query_element
                 ~product_filter:
                   (`Assoc
                      [
                        ( "attributeFilters",
                          `List
                            [
                              `Assoc
                                [
                                  ("key", `String "instanceType");
                                  ("value", `String "t3.micro");
                                  ("value_regex", `String "");
                                ];
                            ] );
                      ])
                 ())
          in
          Oth.Assert.eq
            ~eq:(CCList.equal Ip.Attribute_filter.equal)
            ~pp:(CCList.pp Ip.Attribute_filter.pp)
            [
              {
                Ip.Attribute_filter.key = "instanceType";
                match_ = Ip.Attribute_filter.Eq "t3.micro";
              };
            ]
            filter.Ip.Filter.attribute_filters;
          ());
      Oth.test ~name:"regex: the delimited forms" (fun _ ->
          Oth.Assert.eq
            ~eq:(CCList.equal Ip.Regex.equal)
            ~pp:(CCList.pp Ip.Regex.pp)
            [
              { Ip.Regex.pattern = "^foo"; case = Ip.Regex.Sensitive };
              { Ip.Regex.pattern = "^foo"; case = Ip.Regex.Insensitive };
              { Ip.Regex.pattern = "a/b"; case = Ip.Regex.Insensitive };
              { Ip.Regex.pattern = "(?!.*Unused)Storage"; case = Ip.Regex.Sensitive };
              (* Text that is not delimited matches everything, as the server
                 this replaces did. *)
              { Ip.Regex.pattern = ""; case = Ip.Regex.Sensitive };
              { Ip.Regex.pattern = ""; case = Ip.Regex.Sensitive };
              { Ip.Regex.pattern = ""; case = Ip.Regex.Sensitive };
            ]
            (CCList.map
               Ip.Tests.regex_of_string
               [ "/^foo/"; "/^foo/i"; "/a/b/i"; "/(?!.*Unused)Storage/"; "foo"; "//"; "" ]);
          ());
      Oth.test ~name:"encode: the probe" (fun _ ->
          assert_json
            ~expected:
              (`Assoc
                 [
                   ( "errors",
                     `List
                       [
                         `Assoc
                           [
                             ("extensions", `Assoc [ ("code", `String "INTERNAL_SERVER_ERROR") ]);
                             ( "message",
                               `String
                                 "GraphQL operations must contain a non-empty `query` or a \
                                  `persistedQuery` extension." );
                           ];
                       ] );
                 ])
            (encode Ip.Element.Probe []);
          ());
      Oth.test ~name:"encode: no rows" (fun _ ->
          assert_json
            ~expected:(`Assoc [ ("data", `Assoc [ ("products", `List []) ]) ])
            (encode (Ip.Element.Query empty_filter) []);
          ());
      Oth.test ~name:"encode: prices grouped by product" (fun _ ->
          assert_json
            ~expected:
              (`Assoc
                 [
                   ( "data",
                     `Assoc
                       [
                         ( "products",
                           `List
                             [
                               `Assoc
                                 [
                                   ( "prices",
                                     `List
                                       [
                                         `Assoc
                                           [
                                             ("priceHash", `String "p1");
                                             ("USD", `String "0.0104000000");
                                           ];
                                         `Assoc
                                           [
                                             ("priceHash", `String "p2");
                                             ("USD", `String "0.0208000000");
                                           ];
                                       ] );
                                 ];
                               `Assoc
                                 [
                                   ( "prices",
                                     `List
                                       [
                                         `Assoc
                                           [ ("priceHash", `String "p3"); ("USD", `String "0") ];
                                       ] );
                                 ];
                             ] );
                       ] );
                 ])
            (encode
               (Ip.Element.Query empty_filter)
               [
                 row ~product_hash:"a" ~price_hash:"p1" ~amount:"0.0104000000" ();
                 row ~product_hash:"a" ~price_hash:"p2" ~amount:"0.0208000000" ();
                 row ~product_hash:"b" ~price_hash:"p3" ~amount:"0" ();
               ]);
          ());
      Oth.test ~name:"encode: the currency names the price field" (fun _ ->
          let filter = filter_of (query_element ~currency:"EUR" ()) in
          assert_json
            ~expected:
              (`Assoc
                 [
                   ( "data",
                     `Assoc
                       [
                         ( "products",
                           `List
                             [
                               `Assoc
                                 [
                                   ( "prices",
                                     `List
                                       [
                                         `Assoc
                                           [
                                             ("priceHash", `String "p1");
                                             ("EUR", `String "0.0088815376");
                                           ];
                                       ] );
                                 ];
                             ] );
                       ] );
                 ])
            (encode
               (Ip.Element.Query filter)
               [ row ~product_hash:"a" ~price_hash:"p1" ~amount:"0.0088815376" () ]);
          ());
      Oth.test ~name:"encode: a price with no amount" (fun _ ->
          assert_json
            ~expected:
              (`Assoc
                 [
                   ( "data",
                     `Assoc
                       [
                         ( "products",
                           `List
                             [
                               `Assoc
                                 [
                                   ( "prices",
                                     `List
                                       [ `Assoc [ ("priceHash", `String "p1"); ("USD", `Null) ] ] );
                                 ];
                             ] );
                       ] );
                 ])
            (encode (Ip.Element.Query empty_filter) [ row ~product_hash:"a" ~price_hash:"p1" () ]);
          ());
      Oth.test ~name:"cny: a price with only a yuan amount takes it" (fun _ ->
          assert_prices
            ~expected:(products [ [ ("p1", Some "0.0770000000") ] ])
            empty_filter
            [ row ~product_hash:"a" ~price_hash:"p1" ~cny_amount:"0.0770000000" () ];
          ());
      Oth.test ~name:"cny: the twin merges into a price with no US dollar amount" (fun _ ->
          assert_prices
            ~expected:(products [ [ ("p1", Some "0.0770000000") ] ])
            empty_filter
            [
              row ~cny_merge:Ip.Tests.Row.Merge_cny ~product_hash:"a" ~price_hash:"p1" ();
              row
                ~cny_merge:Ip.Tests.Row.Merge_cny
                ~product_hash:"a"
                ~price_hash:"p1-cny"
                ~cny_amount:"0.0770000000"
                ();
            ];
          ());
      Oth.test ~name:"cny: the twin leaves a price that has a US dollar amount" (fun _ ->
          assert_prices
            ~expected:(products [ [ ("p1", Some "0.5000000000") ] ])
            empty_filter
            [
              row
                ~cny_merge:Ip.Tests.Row.Merge_cny
                ~product_hash:"a"
                ~price_hash:"p1"
                ~amount:"0.5000000000"
                ();
              row
                ~cny_merge:Ip.Tests.Row.Merge_cny
                ~product_hash:"a"
                ~price_hash:"p1-cny"
                ~cny_amount:"0.0770000000"
                ();
            ];
          ());
      Oth.test ~name:"cny: a yuan price with no twin stays" (fun _ ->
          assert_prices
            ~expected:(products [ [ ("p1-cny", Some "0.0770000000") ] ])
            empty_filter
            [
              row
                ~cny_merge:Ip.Tests.Row.Merge_cny
                ~product_hash:"a"
                ~price_hash:"p1-cny"
                ~cny_amount:"0.0770000000"
                ();
            ];
          ());
      Oth.test ~name:"cny: a yuan group of two does not merge" (fun _ ->
          assert_prices
            ~expected:
              (products
                 [
                   [
                     ("p1", None); ("p1-cny", Some "0.0770000000"); ("p1-cny", Some "0.0880000000");
                   ];
                 ])
            empty_filter
            [
              row ~cny_merge:Ip.Tests.Row.Merge_cny ~product_hash:"a" ~price_hash:"p1" ();
              row
                ~cny_merge:Ip.Tests.Row.Merge_cny
                ~product_hash:"a"
                ~price_hash:"p1-cny"
                ~cny_amount:"0.0770000000"
                ();
              row
                ~cny_merge:Ip.Tests.Row.Merge_cny
                ~product_hash:"a"
                ~price_hash:"p1-cny"
                ~cny_amount:"0.0880000000"
                ();
            ];
          ());
      Oth.test ~name:"cny: the usage amounts must be the same" (fun _ ->
          assert_prices
            ~expected:(products [ [ ("p1", None); ("p1-cny", Some "0.0770000000") ] ])
            empty_filter
            [
              row
                ~cny_merge:Ip.Tests.Row.Merge_cny
                ~product_hash:"a"
                ~price_hash:"p1"
                ~start_usage_amount:"0"
                ();
              row
                ~cny_merge:Ip.Tests.Row.Merge_cny
                ~product_hash:"a"
                ~price_hash:"p1-cny"
                ~start_usage_amount:"100"
                ~cny_amount:"0.0770000000"
                ();
            ];
          ());
      Oth.test ~name:"cny: a product that does not merge keeps both prices" (fun _ ->
          assert_prices
            ~expected:(products [ [ ("p1", None); ("p1-cny", Some "0.0770000000") ] ])
            empty_filter
            [
              row ~product_hash:"a" ~price_hash:"p1" ();
              row ~product_hash:"a" ~price_hash:"p1-cny" ~cny_amount:"0.0770000000" ();
            ];
          ());
    ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
