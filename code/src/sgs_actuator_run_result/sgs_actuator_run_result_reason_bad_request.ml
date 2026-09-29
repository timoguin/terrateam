module Kind = struct
  let t_of_yojson = function
    | `String "bad_request" -> Ok `Bad_request
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Bad_request -> `String "bad_request"

  type t = ([ `Bad_request ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  data : string option; [@default None]
  id : string;
  kind : Kind.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
