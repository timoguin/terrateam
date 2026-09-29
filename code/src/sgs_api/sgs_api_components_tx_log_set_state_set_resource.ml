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
  module Mode = struct
    let t_of_yojson = function
      | `String "data" -> Ok `Data
      | `String "managed" -> Ok `Managed
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Data -> `String "data"
      | `Managed -> `String "managed"

    type t =
      ([ `Data
       | `Managed
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    address : string;
    mode : Mode.t;
    module_ : string option; [@default None] [@key "module"]
    name : string;
    provider : string option; [@default None]
    type_ : string; [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Object_type = struct
  let t_of_yojson = function
    | `String "resource" -> Ok `Resource
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Resource -> `String "resource"

  type t = ([ `Resource ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  action : Action.t;
  data : Data.t;
  object_type : Object_type.t;
  state_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
