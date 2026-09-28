module Provider = struct
  let t_of_yojson = function
    | `String "aws" -> Ok `Aws
    | `String "azure" -> Ok `Azure
    | `String "gcp" -> Ok `Gcp
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Aws -> `String "aws"
    | `Azure -> `String "azure"
    | `Gcp -> `String "gcp"

  type t =
    ([ `Aws
     | `Azure
     | `Gcp
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Warnings = struct
  module Items = struct
    include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  provider : Provider.t;
  ready_for_gap_analysis : bool;
  ready_for_terraform_import : bool option; [@default None]
  status : string;
  warnings : Warnings.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
