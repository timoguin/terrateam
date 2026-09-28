module Kind = struct
  let t_of_yojson = function
    | `String "params_fetch" -> Ok `Params_fetch
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Params_fetch -> `String "params_fetch"

  type t = ([ `Params_fetch ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { kind : Kind.t } [@@deriving yojson { strict = false; meta = true }, make, show, eq]
