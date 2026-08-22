module Make (Abb : Abb_intf.S) = struct
  module Oth_abb = Abb_test_oth.Make (Abb)

  (* A closed socket must reject further operations, and [close] must be
     idempotent (a second close cannot fail or double-close a recycled fd). *)
  let socket_closed_ops_fail =
    Oth_abb.test
      ~desc:"Closed socket rejects ops and close is idempotent"
      ~name:"socket_closed_ops_fail"
      (fun () ->
        let open Abb.Future.Infix_monad in
        match Abb.Socket.Tcp.create ~domain:Abb_intf.Socket.Domain.Inet4 with
        | Error _ -> Oth.Assert.false_ "socket create failed"
        | Ok sock ->
            Oth.Assert.true_ "a fresh socket is not closed" (not (Abb.Socket.is_closed sock));
            Abb.Socket.close sock
            >>= fun _ ->
            Oth.Assert.true_ "a closed socket reports closed" (Abb.Socket.is_closed sock);
            Abb.Socket.close sock
            >>= fun second_close ->
            ignore (Oth.Assert.ok ~fail_msg:"second close should succeed" second_close);
            let buf = Bytes.create 8 in
            Abb.Socket.Tcp.recv sock ~buf ~pos:0 ~len:8
            >>= fun recv_res ->
            ignore (Oth.Assert.error ~fail_msg:"recv on a closed socket should fail" recv_res);
            let wb = Abb_intf.Write_buf.{ buf = Bytes.of_string "x"; pos = 0; len = 1 } in
            Abb.Socket.Tcp.send sock ~bufs:[ wb ]
            >>= fun send_res ->
            ignore (Oth.Assert.error ~fail_msg:"send on a closed socket should fail" send_res);
            Abb.Future.return ())

  (* Writability after [EINPROGRESS] means the connect FINISHED, not that it
     succeeded: a refused connect reports exactly the same readiness.  A
     scheduler that answers readiness alone reports every failed connect as a
     success, and hands the caller a socket that is not connected to anything. *)
  let refused_connect_fails =
    Oth_abb.test
      ~desc:"Connecting to a closed port reports the refusal rather than success"
      ~name:"refused_connect_fails"
      (fun () ->
        let open Abb.Future.Infix_monad in
        match Abb.Socket.Tcp.create ~domain:Abb_intf.Socket.Domain.Inet4 with
        | Error _ -> Oth.Assert.false_ "socket create failed"
        | Ok sock ->
            Abb.Socket.Tcp.connect
              sock
              Abb_intf.Socket.Sockaddr.(Inet { addr = Unix.inet_addr_loopback; port = 1 })
            >>= fun res ->
            ignore
              (Oth.Assert.error ~fail_msg:"connect to a closed port must not report success" res);
            Abb.Socket.close sock >>= fun _ -> Abb.Future.return ())

  let test = Oth_abb.serial [ socket_closed_ops_fail; refused_connect_fails ]
end
