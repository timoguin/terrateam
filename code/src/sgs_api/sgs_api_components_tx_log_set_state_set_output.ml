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
  module Type = struct
    type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Value = struct
    type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    address : string;
    name : string;
    sensitive : bool option; [@default None]
    type_ : Type.t; [@key "type"]
    value : Value.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Object_type = struct
  let t_of_yojson = function
    | `String "output" -> Ok `Output
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Output -> `String "output"

  type t = ([ `Output ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  action : Action.t;
  data : Data.t;
  object_type : Object_type.t;
  state_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
