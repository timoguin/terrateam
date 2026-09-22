module Oth_abb = Oth_abb.Make (Abb)
module Ip = Infracost_pricing

let query =
  Ip.Element.Query
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

(* No connection is made before [Pgsql_pool.with_conn], and nothing listens on
   port 1. *)
let unreachable_pool () =
  Pgsql_pool.create
    ~connect_timeout:1.0
    ~host:"127.0.0.1"
    ~port:1
    ~user:"nobody"
    ~max_conns:1
    "nothing"

let test_probes_need_no_connection =
  Oth_abb.test ~name:"run: a batch of probes needs no connection" (fun () ->
      let open Abb.Future.Infix_monad in
      unreachable_pool ()
      >>= fun pool ->
      Ip.run pool [ Ip.Element.Probe; Ip.Element.Probe ]
      >>= fun result ->
      (match result with
      | Ok responses ->
          Oth.Assert.Eq.string
            ~expected:
              (Yojson.Safe.to_string
                 (Terrat_api_components.Infracost_graphql_batch_response.to_yojson
                    [ Ip.Tests.encode Ip.Element.Probe []; Ip.Tests.encode Ip.Element.Probe [] ]))
            ~actual:
              (Yojson.Safe.to_string
                 (Terrat_api_components.Infracost_graphql_batch_response.to_yojson responses))
      | Error (#Pgsql_io.err as err) -> Oth.Assert.false_ (Pgsql_io.show_err err)
      | Error `Pgsql_pool_error -> Oth.Assert.false_ "the probes took a connection");
      Pgsql_pool.destroy pool)

let test_query_takes_a_connection =
  Oth_abb.test ~name:"run: a batch with a query takes a connection" (fun () ->
      let open Abb.Future.Infix_monad in
      unreachable_pool ()
      >>= fun pool ->
      Ip.run pool [ Ip.Element.Probe; query ]
      >>= fun result ->
      (match result with
      | Error `Pgsql_pool_error -> ()
      | Ok _ -> Oth.Assert.false_ "the query answered without a connection"
      | Error (#Pgsql_io.err as err) -> Oth.Assert.false_ (Pgsql_io.show_err err));
      Pgsql_pool.destroy pool)

let test = Oth_abb.parallel [ test_probes_need_no_connection; test_query_takes_a_connection ]

let () =
  Random.self_init ();
  Oth_abb.run
    ~file:__FILE__
    ~setup:(fun () -> Abb.Future.return (Ok ()))
    ~teardown:(fun () -> Abb.Future.return ())
    (fun () -> test)
