type output_err =
  [ Abb_intf.Errors.spawn
  | Abb_intf.Errors.write
  | Abb_intf.Errors.read
  | Abb_intf.Errors.close
  ]
[@@deriving show]

module Make (Abb : Abb_intf.S with type Native.t = Unix.file_descr) = struct
  module Fut_comb = Abb_future_combinators.Make (Abb.Future)

  let read_all file =
    let buffer = Buffer.create 1024 in
    let bytes = Bytes.create 1024 in
    let len = Bytes.length bytes in
    let rec read_data buffer file bytes =
      let open Fut_comb.Infix_result_monad in
      Abb.File.read file ~buf:bytes ~pos:0 ~len
      >>= function
      | 0 -> Abb.Future.return (Ok (Buffer.contents buffer))
      | n ->
          Buffer.add_subbytes buffer bytes 0 n;
          read_data buffer file bytes
    in
    read_data buffer file bytes

  let output ?input process =
    let open Fut_comb.Infix_result_monad in
    let (stdin_r, stdin_w) = Unix.pipe ~cloexec:false () in
    let (stdout_r, stdout_w) = Unix.pipe ~cloexec:false () in
    let (stderr_r, stderr_w) = Unix.pipe ~cloexec:false () in
    let stdin_dup = Abb_intf.Process.Dup.create ~src:stdin_r ~dst:Unix.stdin in
    let stdout_dup = Abb_intf.Process.Dup.create ~src:stdout_w ~dst:Unix.stdout in
    let stderr_dup = Abb_intf.Process.Dup.create ~src:stderr_w ~dst:Unix.stderr in
    let stdin_w = Abb.File.of_native stdin_w in
    let stdout_r = Abb.File.of_native stdout_r in
    let stderr_r = Abb.File.of_native stderr_r in
    match Abb.Process.spawn process [ stdin_dup; stdout_dup; stderr_dup ] with
      | Ok process     -> (
          (match input with
            | Some input ->
                Abb.File.write
                  stdin_w
                  Abb_intf.Write_buf.
                    [ { buf = Bytes.of_string input; pos = 0; len = String.length input } ]
                >>= fun n ->
                assert (n = String.length input);
                Abb.Future.return (Ok ())
            | None       -> Abb.Future.return (Ok ()))
          >>= fun () ->
          Abb.File.close stdin_w
          >>= fun () ->
          let open Abb.Future.Infix_monad in
          Abb.Future.Infix_app.(
            (fun stdout stderr exit_code -> (stdout, stderr, exit_code))
            <$> read_all stdout_r
            <*> read_all stderr_r
            <*> Abb.Process.wait process)
          >>| function
          | (Ok stdout, Ok stderr, exit_code) -> Ok (stdout, stderr, exit_code)
          | ((Error _ as err), _, _) | (_, (Error _ as err), _) -> err)
      | Error _ as err -> Abb.Future.return err
end