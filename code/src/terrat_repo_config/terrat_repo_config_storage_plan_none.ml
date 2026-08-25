module Method = struct
  let t_of_yojson = function
    | `String "none" -> Ok `None
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `None -> `String "none"

  type t = ([ `None ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  method_ : Method.t; [@key "method"]
  unsafe_apply_without_plan : bool; [@default false]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
