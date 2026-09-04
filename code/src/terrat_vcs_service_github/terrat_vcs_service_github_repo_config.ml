module Api = Terrat_vcs_api_github

module Candidate = struct
  type t = {
    path : string;
    size : int;
  }
  [@@deriving show, eq]
end

(* What the contents endpoint said about one directory.  [Listed] holds its
   entries, which is the empty list when the directory does not exist.
   [Unlistable] means the endpoint refused to list it, and the names must be
   read one by one. *)
type listing =
  | Listed of Api.Directory_entry.t list
  | Unlistable

type listings = (string * listing) list

(* The paths of the GitHub contents endpoint always use [/], thus do not use
   [Filename.concat], which uses the separator of the host. *)
let path_of ~directory ~name = directory ^ "/" ^ name

let find_file entries name =
  CCList.find_opt
    (fun entry ->
      match Api.Directory_entry.kind entry with
      | `File -> CCString.equal (Api.Directory_entry.name entry) name
      | `Dir | `Submodule | `Symlink -> false)
    entries

let find_candidate entries ~directory ~basename =
  let candidate extension =
    let name = basename ^ extension in
    find_file entries name
    |> CCOption.map (fun entry ->
        { Candidate.path = path_of ~directory ~name; size = Api.Directory_entry.size entry })
  in
  CCOption.or_lazy ~else_:(fun () -> candidate ".yaml") (candidate ".yml")

let list_directories ~request_id client repo ref_ directories =
  let open Abb.Future.Infix_monad in
  Abbs_future_combinators.List.map_par
    ~f:(fun directory ->
      Api.fetch_directory ~request_id client repo ref_ directory
      >>| function
      | Ok entries -> Ok (directory, Listed (CCOption.get_or ~default:[] entries))
      | Error `Listing_unavailable -> Ok (directory, Unlistable)
      | Error (#Terrat_vcs_api.call_err as err) -> Error err)
    directories
  >>| CCResult.flatten_l

let decode repo ref_ path content =
  let open Abbs_future_combinators.Infix_result_monad in
  if CCString.is_empty (CCString.trim content) then Abbs_future_combinators.return_ok None
  else
    let fname = Api.Repo.to_string repo ^ ":" ^ Api.Ref.to_string ref_ ^ ":" ^ path in
    Abb.Future.return
      (CCResult.map_err
         (fun (`Yaml_decode_err err) -> `Yaml_decode_err (fname, err))
         (Jsonu.of_yaml_string content))
    >>| fun json -> Some (fname, json)

(* The listing already gave the size, thus an empty file needs no read. *)
let fetch_candidate ~request_id client repo ref_ { Candidate.path; size } =
  let open Abbs_future_combinators.Infix_result_monad in
  match size with
  | 0 -> Abbs_future_combinators.return_ok None
  | _ -> (
      Api.fetch_file ~request_id client repo ref_ path
      >>= function
      | None -> Abbs_future_combinators.return_ok None
      | Some content -> decode repo ref_ path content)

(* Read both names when the directory could not be listed.  The [.yml] name
   wins when it exists, even when it holds nothing, which is what the listing
   path does as well. *)
let probe ~request_id client repo ref_ ~directory ~basename =
  let open Abbs_future_combinators.Infix_result_monad in
  let yml = path_of ~directory ~name:(basename ^ ".yml") in
  let yaml = path_of ~directory ~name:(basename ^ ".yaml") in
  Abbs_future_combinators.Result.all2
    (Api.fetch_file ~request_id client repo ref_ yml)
    (Api.fetch_file ~request_id client repo ref_ yaml)
  >>= function
  | Some content, _ -> decode repo ref_ yml content
  | None, Some content -> decode repo ref_ yaml content
  | None, None -> Abbs_future_combinators.return_ok None

let fetch_config ~request_id client repo ref_ listings ~directory ~basename =
  (* A directory that [list_directories] did not read is unknown here, thus
     read its names directly.  That answer is the same, it only costs a
     request. *)
  match CCList.assoc_opt ~eq:CCString.equal directory listings with
  | Some (Listed entries) ->
      find_candidate entries ~directory ~basename
      |> CCOption.map_or
           ~default:(Abbs_future_combinators.return_ok None)
           (fetch_candidate ~request_id client repo ref_)
  | Some Unlistable | None -> probe ~request_id client repo ref_ ~directory ~basename

(* Config parity (#1442): [.stategraph/config] wins when both exist;
   [.terrateam/config] keeps working so existing repos need no rename. *)
let fetch ~request_id client repo ref_ =
  let open Abbs_future_combinators.Infix_result_monad in
  list_directories ~request_id client repo ref_ [ ".stategraph"; ".terrateam" ]
  >>= fun listings ->
  fetch_config ~request_id client repo ref_ listings ~directory:".stategraph" ~basename:"config"
  >>= function
  | Some _ as config -> Abbs_future_combinators.return_ok config
  | None ->
      fetch_config ~request_id client repo ref_ listings ~directory:".terrateam" ~basename:"config"

module Tests = struct
  let find_candidate = find_candidate
end
