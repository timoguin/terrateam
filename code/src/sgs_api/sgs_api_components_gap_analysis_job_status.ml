module Status = struct
  let t_of_yojson = function
    | `String "completed" -> Ok `Completed
    | `String "failed" -> Ok `Failed
    | `String "running" -> Ok `Running
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Completed -> `String "completed"
    | `Failed -> `String "failed"
    | `Running -> `String "running"

  type t =
    ([ `Completed
     | `Failed
     | `Running
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  error : string option; [@default None]
  started_at : string;
  status : Status.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
