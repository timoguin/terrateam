module Action = struct
  let t_of_yojson = function
    | `String "tfvar_delete" -> Ok `Tfvar_delete
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Tfvar_delete -> `String "tfvar_delete"

  type t = ([ `Tfvar_delete ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Data = struct
  type t = { node_id : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Object_type = struct
  let t_of_yojson = function
    | `String "tfvar" -> Ok `Tfvar
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Tfvar -> `String "tfvar"

  type t = ([ `Tfvar ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  action : Action.t;
  data : Data.t;
  object_type : Object_type.t;
  state_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
