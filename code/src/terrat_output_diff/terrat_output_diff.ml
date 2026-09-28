type shape =
  | Tf_wrapped
  | Raw

type t = {
  shape : shape;
  baseline : Yojson.Safe.t option;
  current : Yojson.Safe.t option;
}

(* One output as [output -json] writes it. Only [value] is read. *)
module Wrapped = struct
  type t = { value : Yojson.Safe.t } [@@deriving of_yojson { strict = false }]
end

module Tf_outputs = struct
  type t = Wrapped.t Sln_map.String.t [@@deriving of_yojson]
end

module Raw_outputs = struct
  type t = Yojson.Safe.t Sln_map.String.t [@@deriving of_yojson]
end

(* Decode one side into a map from output name to value, so both shapes compare the same way.
   Terraform outputs that do not all decode as wrapped outputs are read as raw.  JSON that is not an
   object has no output names, thus it is the same as no outputs. *)
let outputs shape json =
  let raw json = CCResult.get_or ~default:Sln_map.String.empty (Raw_outputs.of_yojson json) in
  match (shape, json) with
  | _, None -> Sln_map.String.empty
  | Raw, Some json -> raw json
  | Tf_wrapped, Some json -> (
      match Tf_outputs.of_yojson json with
      | Ok outputs -> Sln_map.String.map (fun { Wrapped.value } -> value) outputs
      | Error _ -> raw json)

(* The value of an output is JSON that the user defines, thus the path below the output name walks
   it as JSON. *)
let select path json =
  CCList.fold_left
    (fun json key ->
      match json with
      | `Assoc fields ->
          CCOption.get_or ~default:`Null (CCList.assoc_opt ~eq:CCString.equal key fields)
      | _ -> `Null)
    json
    path

let changed_at ~baseline ~current name path =
  let value outputs =
    select path (CCOption.get_or ~default:`Null (Sln_map.String.find_opt name outputs))
  in
  not (Yojson.Safe.equal (value baseline) (value current))

let changed { shape; baseline; current } ~path =
  let baseline = outputs shape baseline in
  let current = outputs shape current in
  match path with
  | Some (name :: path) -> changed_at ~baseline ~current name path
  | Some [] | None ->
      (* Compare output by output, so an output that is [null] on one side and absent on the other
         is not a change. *)
      Sln_set.String.exists
        (fun name -> changed_at ~baseline ~current name [])
        (Sln_set.String.union (Sln_map.String.keys_set baseline) (Sln_map.String.keys_set current))
