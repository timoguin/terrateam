let t_of_yojson = function
  | `String "code_scanning" -> Ok `Code_scanning
  | `String "secret_scanning" -> Ok `Secret_scanning
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Code_scanning -> `String "code_scanning"
  | `Secret_scanning -> `String "secret_scanning"

type t =
  ([ `Code_scanning
   | `Secret_scanning
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
