let version = 1

module Cmdline = struct
  module C = Cmdliner

  let paths =
    let doc = "Directories to process." in
    C.Arg.(non_empty & pos_all string [] & info ~docv:"PATH" ~doc [])

  let index_cmd f =
    let doc = "Index paths" in
    let exits = C.Cmd.Exit.defaults in
    C.Cmd.v (C.Cmd.info "index" ~doc ~exits) C.Term.(const f $ paths)
end

let default_tf_matcher = Path_glob.Glob.parse "<*.tf>"

module String_map = struct
  include CCMap.Make (CCString)

  let to_yojson f t = `Assoc (CCList.map (fun (k, v) -> (k, f v)) (to_list t))

  let of_yojson f = function
    | `Assoc obj -> (
        try
          Ok
            (CCListLabels.fold_left
               ~f:(fun acc (k, v) ->
                 match f v with
                 | Ok v -> add k v acc
                 | Error err -> failwith err)
               ~init:empty
               obj)
        with Failure err -> Error err)
    | _ -> Error "Expected object"
end

module Output = struct
  module Failure = struct
    type t = {
      lnum : int option;
      msg : string;
    }
    [@@deriving yojson]
  end

  module Dep = struct
    type t = {
      modules : string list;
      failures : Failure.t String_map.t;
    }
    [@@deriving yojson]
  end

  type t = {
    version : int;
    paths : Dep.t String_map.t;
  }
  [@@deriving yojson]
end

let rec concat_path f1 f2 =
  if CCString.prefix ~pre:"./" f2 then concat_path f1 (CCString.drop 2 f2)
  else if CCString.prefix ~pre:"../" f2 then concat_path (Filename.dirname f1) (CCString.drop 3 f2)
  else Filename.concat f1 f2

let rec process_path base path =
  let files =
    Sys.readdir path
    |> CCArray.to_list
    |> CCList.filter (Path_glob.Glob.eval default_tf_matcher)
    |> CCList.map (Filename.concat path)
  in
  CCList.flat_map
    (fun path ->
      let contents = CCIO.with_in path CCIO.read_all in
      match Hcl_ast.of_string contents with
      | Ok ast ->
          CCList.flat_map
            (fun m ->
              if Opentofu_mods.Module.is_source_local_path m then
                [
                  `Module
                    (CCOption.map_or
                       ~default:(Opentofu_mods.Module.source m)
                       CCFun.(flip concat_path (Opentofu_mods.Module.source m))
                       base);
                ]
                @ process_path
                    (Some (Opentofu_mods.Module.source m))
                    (concat_path (Filename.dirname path) (Opentofu_mods.Module.source m))
              else [])
            (Opentofu_mods.collect_modules ast)
      | Error (`Error (pos, _, err)) -> [ `Error (path, pos, err) ])
    files

let index paths =
  let output =
    {
      Output.version;
      paths =
        String_map.of_list
          (CCList.map
             (fun path ->
               ( path,
                 CCListLabels.fold_left
                   ~f:(fun acc -> function
                     | `Module m -> Output.Dep.{ acc with modules = m :: acc.modules }
                     | `Error (fname, pos, msg) ->
                         Output.Dep.
                           {
                             acc with
                             failures =
                               String_map.add
                                 fname
                                 {
                                   Output.Failure.lnum =
                                     CCOption.map (fun { Hcl_ast.lnum; _ } -> lnum) pos;
                                   msg;
                                 }
                                 acc.failures;
                           })
                   ~init:Output.Dep.{ modules = []; failures = String_map.empty }
                   (process_path None path) ))
             paths);
    }
  in
  print_endline (Yojson.Safe.pretty_to_string (Output.to_yojson output))

let cmds = Cmdline.[ index_cmd index ]

let () =
  let info = Cmdliner.Cmd.info (Filename.basename Sys.argv.(0)) in
  exit @@ Cmdliner.Cmd.eval @@ Cmdliner.Cmd.group info cmds