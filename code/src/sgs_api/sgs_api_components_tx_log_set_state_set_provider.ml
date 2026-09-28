module Action = struct
  let t_of_yojson = function
    | `String "state_set" -> Ok `State_set
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `State_set -> `String "state_set"

  type t = ([ `State_set ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Data = struct
  type t = { name : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Object_type = struct
  let t_of_yojson = function
    | `String "provider" -> Ok `Provider
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Provider -> `String "provider"

  type t = ([ `Provider ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  action : Action.t;
  data : Data.t;
  object_type : Object_type.t;
  state_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
