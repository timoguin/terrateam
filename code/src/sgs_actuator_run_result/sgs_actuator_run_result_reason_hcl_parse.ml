module Kind = struct
  let t_of_yojson = function
    | `String "hcl_parse" -> Ok `Hcl_parse
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Hcl_parse -> `String "hcl_parse"

  type t = ([ `Hcl_parse ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { kind : Kind.t } [@@deriving yojson { strict = false; meta = true }, make, show, eq]
