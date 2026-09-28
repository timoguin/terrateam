module Kind = struct
  let t_of_yojson = function
    | `String "preview_fetch" -> Ok `Preview_fetch
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Preview_fetch -> `String "preview_fetch"

  type t = ([ `Preview_fetch ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { kind : Kind.t } [@@deriving yojson { strict = false; meta = true }, make, show, eq]
