module Action = struct
  let t_of_yojson = function
    | `String "file_set" -> Ok `File_set
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `File_set -> `String "file_set"

  type t = ([ `File_set ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Object_type = struct
  let t_of_yojson = function
    | `String "file" -> Ok `File
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `File -> `String "file"

  type t = ([ `File ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  action : Action.t;
  data : Sgs_tx_log_data_file_set.t;
  object_type : Object_type.t;
  state_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
