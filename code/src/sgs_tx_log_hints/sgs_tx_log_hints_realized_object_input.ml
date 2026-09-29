module Kind = struct
  let t_of_yojson = function
    | `String "file_list" -> Ok `File_list
    | `String "file_ref" -> Ok `File_ref
    | `String "file_ref_path" -> Ok `File_ref_path
    | `String "fq_address" -> Ok `Fq_address
    | `String "tfvar" -> Ok `Tfvar
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `File_list -> `String "file_list"
    | `File_ref -> `String "file_ref"
    | `File_ref_path -> `String "file_ref_path"
    | `Fq_address -> `String "fq_address"
    | `Tfvar -> `String "tfvar"

  type t =
    ([ `File_list
     | `File_ref
     | `File_ref_path
     | `Fq_address
     | `Tfvar
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  key : string;
  kind : Kind.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
