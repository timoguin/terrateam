module Kind = struct
  let t_of_yojson = function
    | `String "next_timeout" -> Ok `Next_timeout
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Next_timeout -> `String "next_timeout"

  type t = ([ `Next_timeout ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  kind : Kind.t;
  seconds : int;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
