module Attr_path = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Kind = struct
  let t_of_yojson = function
    | `String "binds" -> Ok `Binds
    | `String "reads" -> Ok `Reads
    | `String "reads_file" -> Ok `Reads_file
    | `String "reads_tfvar" -> Ok `Reads_tfvar
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Binds -> `String "binds"
    | `Reads -> `String "reads"
    | `Reads_file -> `String "reads_file"
    | `Reads_tfvar -> `String "reads_tfvar"

  type t =
    ([ `Binds
     | `Reads
     | `Reads_file
     | `Reads_tfvar
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  attr_path : Attr_path.t;
  from_id : string;
  kind : Kind.t;
  to_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
