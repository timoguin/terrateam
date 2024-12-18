module List = ListLabels

type connect_http_err = Abb_happy_eyeballs.connect_err [@@deriving show]

type connect_https_err =
  [ connect_http_err
  | `Error
  | Abb_happy_eyeballs.connect_err
  ]
[@@deriving show]

type request_err =
  [ connect_https_err
  | `E_connection_refused
  | `Invalid_scheme of string
  | `Invalid of string
  ]
[@@deriving show]

type run_err =
  [ `Exn of (exn[@printer fun fmt v -> fprintf fmt "%s" (Printexc.to_string v)])
  | `E_address_family_not_supported
  | `E_address_in_use
  | `E_address_not_available
  ]
[@@deriving show]

module Make (Abb : Abb_intf.S with type Native.t = Unix.file_descr) = struct
  module Happy_eyeballs = Abb_happy_eyeballs.Make (Abb)
  module Channel = Abb_channel.Make (Abb.Future)
  module Channel_queue = Abb_channel_queue.Make (Abb.Future)
  module Fut_comb = Abb_future_combinators.Make (Abb.Future)
  module Io = Cohttp_abb_io.Make (Abb)
  module Buffered = Abb_io_buffered.Make (Abb.Future)
  module Buffered_of = Abb_io_buffered.Of (Abb)
  module Abb_tls = Abb_tls.Make (Abb)
  module Request = Cohttp.Request
  module Response = Cohttp.Response
  module Body = Cohttp.Body
  module Request_io = Cohttp.Request.Make (Io)
  module Response_io = Cohttp.Response.Make (Io)

  module Client = struct
    module Scheme = struct
      type t =
        | Http
        | Https of Otls.Tls_config.t
    end

    let connect_to_port host port conv =
      let open Fut_comb.Infix_result_monad in
      Happy_eyeballs.connect host [ port ] >>= fun (_, sock) -> Abb.Future.return (Ok (conv sock))

    let connect_http uri =
      let host = CCOption.get_exn_or "get host" (Uri.host uri) in
      let port = CCOption.get_or ~default:80 (Uri.port uri) in
      connect_to_port host port Buffered_of.of_tcp_socket

    let connect_https conf uri =
      let open Fut_comb.Infix_result_monad in
      let host = CCOption.get_exn_or "get host" (Uri.host uri) in
      let port = CCOption.get_or ~default:443 (Uri.port uri) in
      connect_to_port host port CCFun.id
      >>= fun conn -> Abb.Future.return (Abb_tls.client_tcp conn conf host)

    let write_body writer = function
      | `Empty -> Abb.Future.return ()
      | `String s -> Request_io.write_body writer s
      | `Strings ss -> Fut_comb.List.iter ~f:(Request_io.write_body writer) ss

    let do_request ?(flush = false) ?(body = `Empty) req ic oc =
      let open Abb.Future.Infix_monad in
      Request_io.write ~flush (fun writer -> write_body writer body) req oc
      >>= fun () ->
      Fut_comb.ignore (Buffered.flushed oc)
      >>= fun () ->
      Response_io.read ic
      >>| function
      | `Ok res -> Ok (res, ic)
      | `Eof -> Error `E_connection_refused
      | `Invalid reason as err -> Error err

    let request ?flush ?(body = `Empty) scheme req =
      let open Fut_comb.Infix_result_monad in
      let connect scheme uri =
        match scheme with
        | Scheme.Http -> connect_http uri
        | Scheme.Https tls_config -> connect_https tls_config uri
      in
      connect scheme (Request.uri req)
      >>= fun (ic, oc) ->
      Fut_comb.on_failure
        (fun () -> do_request ?flush ~body req ic oc)
        ~failure:(fun () -> Fut_comb.ignore (Buffered.close_writer oc))

    let rec read_body r b =
      let open Abb.Future.Infix_monad in
      Response_io.read_body_chunk r
      >>= function
      | Cohttp.Transfer.Chunk s ->
          Buffer.add_string b s;
          read_body r b
      | Cohttp.Transfer.Final_chunk s ->
          Buffer.add_string b s;
          Fut_comb.unit
      | Cohttp.Transfer.Done -> Fut_comb.unit

    let call ?flush ?headers ?(chunked = false) ?(body = `Empty) ?tls_config meth uri =
      let open Fut_comb.Infix_result_monad in
      let body_length = Int64.of_int (String.length (Body.to_string body)) in
      let req = Request.make_for_client ?headers ~chunked ~body_length meth uri in
      let scheme =
        match (tls_config, Uri.scheme uri) with
        | _, None | _, Some "http" -> Scheme.Http
        | Some conf, Some "https" -> Scheme.Https conf
        | _, _ -> failwith "nyi"
      in
      request ?flush ~body scheme req
      >>= fun (resp, ic) ->
      Fut_comb.with_finally
        (fun () ->
          match Response_io.has_body resp with
          | `Yes | `Unknown ->
              let open Abb.Future.Infix_monad in
              let b = Buffer.create 1024 in
              read_body (Response_io.make_body_reader resp ic) b
              >>| fun () -> Ok (resp, Buffer.contents b)
          | `No -> Abb.Future.return (Ok (resp, "")))
        ~finally:(fun () -> Fut_comb.ignore (Buffered.close ic))
  end

  module Server = struct
    module Scheme = struct
      type t =
        | Http
        | Https of Otls.Tls_config.t
    end

    type handler =
      Abb.Socket.tcp Abb.Socket.t ->
      Request.t ->
      Request_io.IO.ic ->
      Response_io.IO.oc ->
      [ `Stop | `Ok ] Abb.Future.t

    type on_handler_err =
      Request.t ->
      [ `Timeout | `Exn of exn * Printexc.raw_backtrace option ] ->
      [ `Stop | `Ok ] Abb.Future.t

    type on_protocol_err = [ `Timeout | `Error of string ] -> [ `Stop | `Ok ] Abb.Future.t

    module Config = struct
      module View = struct
        type t = {
          scheme : Scheme.t;
          on_handler_err : on_handler_err;
          on_protocol_err : on_protocol_err;
          port : int;
          handler : handler;
          read_header_timeout : Duration.t option;
          handler_timeout : Duration.t option;
        }
      end

      type t = View.t
      type err = [ `Invalid_port ]

      let of_view = function
        | { View.port; _ } when port <= 0 -> Error `Invalid_port
        | t -> Ok t

      let scheme t = t.View.scheme
      let on_handler_err t = t.View.on_handler_err
      let on_protocol_err t = t.View.on_protocol_err
      let port t = t.View.port
      let handler t = t.View.handler
      let read_header_timeout t = t.View.read_header_timeout
      let handler_timeout t = t.View.handler_timeout
    end

    let read_request timeout_opt r =
      match timeout_opt with
      | Some timeout -> (
          let open Abb.Future.Infix_monad in
          Fut_comb.timeout ~timeout:(Abb.Sys.sleep (Duration.to_f timeout)) (Request_io.read r)
          >>| function
          | `Ok r -> `Req r
          | `Timeout -> `Timeout)
      | None ->
          let open Abb.Future.Infix_monad in
          Request_io.read r >>| fun req -> `Req req

    let rec run_handler config conn r w wc =
      let open Abb.Future.Infix_monad in
      read_request (Config.read_header_timeout config) r
      >>= function
      | `Req (`Ok req) -> (
          Abb.Future.await
            (Fut_comb.on_failure
               (fun () ->
                 match Config.handler_timeout config with
                 | Some timeout ->
                     let timeout = Abb.Sys.sleep (Duration.to_f timeout) >>| fun () -> `Timeout in
                     let handler = Config.handler config conn req r w >>| fun res -> `Res res in
                     Fut_comb.first timeout handler
                     >>= fun (ret, fut) -> Abb.Future.abort fut >>| fun () -> ret
                 | None -> Config.handler config conn req r w >>| fun res -> `Res res)
               ~failure:(fun () -> Fut_comb.ignore (Abb.Socket.close conn)))
          >>= function
          | `Det (`Res (`Ok as ret)) | `Det (`Res (`Stop as ret)) ->
              Fut_comb.ignore (Buffered.flushed w)
              >>= fun () ->
              Fut_comb.ignore (Channel.send wc ret) >>= fun () -> run_handler config conn r w wc
          | `Det (`Timeout as err) | (`Exn _ as err) -> (
              (* On timeout or error, run the error handler, which can only make
                 decisions about whether to continue or stop the server. *)
              Abb.Future.await
                (Fut_comb.on_failure
                   (fun () -> Config.on_handler_err config req err)
                   ~failure:(fun () -> Fut_comb.unit))
              >>= function
              | `Det (`Ok as ret) | `Det (`Stop as ret) ->
                  (* Send an HTTP 500 response. *)
                  Response_io.write
                    (fun writer -> Response_io.write_body writer "")
                    (Cohttp.Response.make ~status:`Internal_server_error ())
                    w
                  >>= fun () ->
                  Fut_comb.ignore (Buffered.flushed w)
                  >>= fun () ->
                  Fut_comb.ignore (Channel.send wc ret) >>= fun () -> run_handler config conn r w wc
              | `Aborted -> Fut_comb.ignore (Channel.send wc `Stop)
              | `Exn (exn, _) -> Fut_comb.ignore (Channel.send wc (`Exn exn)))
          | `Aborted -> Fut_comb.ignore (Abb.Socket.close conn))
      | `Req `Eof ->
          Fut_comb.ignore (Abb.Socket.close conn)
          >>= fun () -> Fut_comb.ignore (Abb.Future.fork (Channel.send wc `Ok))
      | `Req (`Invalid str) -> (
          Fut_comb.ignore (Abb.Socket.close conn)
          >>= fun () ->
          Config.on_protocol_err config (`Error str)
          >>= function
          | `Ok -> Fut_comb.ignore (Channel.send wc `Ok)
          | `Stop -> Fut_comb.ignore (Channel.send wc `Stop))
      | `Timeout -> (
          Fut_comb.ignore (Abb.Socket.close conn)
          >>= fun () ->
          Config.on_protocol_err config `Timeout
          >>= function
          | `Ok -> Fut_comb.ignore (Channel.send wc `Ok)
          | `Stop -> Fut_comb.ignore (Channel.send wc `Stop))

    let rec tcp_accept_loop sock config bf wc =
      let open Abb.Future.Infix_monad in
      Abb.Socket.accept sock
      >>= function
      | Ok conn ->
          bf conn
          >>= fun (r, w) ->
          Abb.Future.fork (run_handler config conn r w wc)
          >>= fun _ -> tcp_accept_loop sock config bf wc
      | Error `E_connection_aborted ->
          (* In the case the client disconnected between accepting and getting
             here, just ignore the error. *)
          tcp_accept_loop sock config bf wc
      | Error `E_bad_file ->
          (* This should never happen. *)
          assert false
      | Error `E_file_table_full ->
          (* TODO: Find a better way to handle this.  It would be nice to be able
             to propogate this error up. *)
          failwith "file table full"
      | Error `E_invalid ->
          (* This should never happen. *)
          assert false
      | Error (`Unexpected _) ->
          (* This should never happen. *)
          assert false

    let rec handler_response_loop config rc =
      let open Abb.Future.Infix_monad in
      Channel.recv rc
      >>= function
      | `Ok `Ok -> handler_response_loop config rc
      | `Ok `Stop -> Abb.Future.return (Ok ())
      | `Ok (`Exn exn) -> Abb.Future.return (Error (`Exn exn))
      | `Closed -> Abb.Future.return (Ok ())

    let run_tcp_server config bf =
      let open Fut_comb.Infix_result_monad in
      let addr =
        Abb_intf.Socket.Sockaddr.(Inet { addr = Unix.inet_addr_any; port = Config.port config })
      in
      let tcp = CCResult.get_exn (Abb.Socket.Tcp.create ~domain:Abb_intf.Socket.Domain.Inet4) in
      Abb.Future.return (Abb.Socket.Tcp.bind tcp addr)
      >>= fun () ->
      Abb.Future.return (Abb.Socket.listen tcp ~backlog:128)
      >>= fun () ->
      Fut_comb.to_result (Channel_queue.T.create ~fast_count:1000 ())
      >>= fun queue ->
      let rc, wc = Channel_queue.to_abb_channel queue in
      let accept_loop = tcp_accept_loop tcp config bf wc in
      Fut_comb.with_finally
        (fun () ->
          let open Abb.Future.Infix_monad in
          Abb.Future.fork accept_loop >>= fun _ -> handler_response_loop config rc)
        ~finally:(fun () -> Channel.close_reader rc)

    let run config =
      let open Abb.Future.Infix_monad in
      let bf conn =
        match Config.scheme config with
        | Scheme.Http -> Abb.Future.return (Buffered_of.of_tcp_socket ~size:4096 conn)
        | Scheme.Https tls_config -> (
            let server = Otls.Tls.server () in
            (* TODO: This can error *)
            ignore (Otls.configure server tls_config);
            match Abb_tls.server_tcp server conn with
            | Ok rw -> Abb.Future.return rw
            | Error `Error -> assert false)
        (* | Ok rw -> Abb.Future.return rw *)
        (* | Error `E_bad_file *)
        (* | Error `E_invalid *)
        (* | Error `E_io *)
        (* | Error `E_is_dir *)
        (* | Error `E_no_space *)
        (* | Error `E_permission *)
        (* | Error `E_pipe *)
        (* | Error `Error *)
        (* | Error (`Unexpected _) -> *)
        (*   (\* Should be impossible *\) *)
        (*   assert false *)
      in
      run_tcp_server config bf
      >>| function
      | Ok () -> Ok ()
      | ( Error (`Exn _)
        | Error `E_address_family_not_supported
        | Error `E_address_in_use
        | Error `E_address_not_available ) as err -> err
      | Error `E_access
      | Error `E_again
      | Error `E_bad_file
      | Error `E_dest_address_required
      | Error `E_invalid
      | Error `E_io
      | Error `E_is_dir
      | Error `E_loop
      | Error `E_name_too_long
      | Error `E_no_entity
      | Error `E_not_dir
      | Error `E_op_not_supported
      | Error `E_permission
      | Error (`Unexpected _) ->
          (* TODO: Handle these. *)
          assert false
  end
end
