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
  module Primary = struct
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
      resource_address : string;
      type_ : string; [@key "type"]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Object_type = struct
  let t_of_yojson = function
    | `String "instance" -> Ok `Instance
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Instance -> `String "instance"

  type t = ([ `Instance ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  action : Action.t;
  data : Data.t;
  object_type : Object_type.t;
  state_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
