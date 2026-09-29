module Kind = struct
  let t_of_yojson = function
    | `String "commit" -> Ok `Commit
    | `String "preview" -> Ok `Preview
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Commit -> `String "commit"
    | `Preview -> `String "preview"

  type t =
    ([ `Commit
     | `Preview
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  dwork_id : string;
  kind : Kind.t option; [@default None]
  task_id : string;
  tx_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
