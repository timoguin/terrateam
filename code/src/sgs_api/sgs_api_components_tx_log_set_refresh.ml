module Action = struct
  let t_of_yojson = function
    | `String "refresh" -> Ok `Refresh
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Refresh -> `String "refresh"

  type t = ([ `Refresh ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Data = struct
  type t = { state_id : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Object_type = struct
  let t_of_yojson = function
    | `String "refresh" -> Ok `Refresh
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Refresh -> `String "refresh"

  type t = ([ `Refresh ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  action : Action.t;
  data : Data.t;
  object_type : Object_type.t;
  state_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
