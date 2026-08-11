module Make (Abb : Abb_intf.S) = struct
  module Oth_abb = Abb_test_oth.Make (Abb)

  let iterations = 200
  let fname = Filename.concat (Filename.get_temp_dir_name ()) "abb_test_file_close.txt"

  let open_write_close () =
    let open Abb.Future.Infix_monad in
    Abb.File.open_file ~flags:Abb_intf.File.Flag.[ Truncate; Write_only; Create 0o600 ] fname
    >>= function
    | Ok file -> (
        let buf = Bytes.of_string "x" in
        Abb.File.write file Abb_intf.Write_buf.[ { buf; pos = 0; len = Bytes.length buf } ]
        >>= function
        | Ok _ ->
            let native = Abb.File.to_native file in
            Abb.File.close file >>= fun _ -> Abb.Future.return native
        | Error _ -> Oth.Assert.false_ "file write failed")
    | Error _ -> Oth.Assert.false_ "opening file for write failed"

  (* [close] must not resolve until the descriptor is actually closed.  A caller
     that opens and closes files in sequence -- [Abb_io_file.with_file_out] over
     a directory of files, say -- never otherwise yields to the scheduler, so a
     [close] that resolves early leaves one live descriptor per iteration until
     the process hits [EMFILE].  Descriptors that are really closed get handed
     back out, so the count of DISTINCT descriptors stays small; a leak makes
     every iteration a fresh one.  Counting distinct rather than requiring one
     fixed number leaves room for a scheduler whose own machinery takes and
     releases descriptors between iterations. *)
  let distinct_fds_test =
    Oth_abb.test
      ~desc:"close resolves only after the fd is closed"
      ~name:"File close does not leak fds"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let rec loop seen n =
          if n = 0 then Abb.Future.return seen
          else open_write_close () >>= fun native -> loop (native :: seen) (n - 1)
        in
        loop [] iterations
        >>= fun seen ->
        let distinct = CCList.length (CCList.uniq ~eq:( = ) seen) in
        Oth.Assert.true_
          (Printf.sprintf
             "%d distinct descriptors over %d open/close cycles: close is resolving before the fd \
              is closed"
             distinct
             iterations)
          (distinct * 10 <= iterations);
        Abb.File.unlink fname >>= fun _ -> Abb.Future.return ())

  let test = Oth_abb.serial [ distinct_fds_test ]
end
