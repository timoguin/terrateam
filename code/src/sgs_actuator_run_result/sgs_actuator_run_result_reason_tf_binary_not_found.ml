module Kind = struct
  let t_of_yojson = function
    | `String "tf_binary_not_found" -> Ok `Tf_binary_not_found
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Tf_binary_not_found -> `String "tf_binary_not_found"

  type t = ([ `Tf_binary_not_found ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  kind : Kind.t;
  tf : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
