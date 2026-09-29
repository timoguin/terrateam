module Type = struct
  let t_of_yojson = function
    | `String "apply-auto-approve" -> Ok `Apply_auto_approve
    | `String "commit" -> Ok `Commit
    | `String "done" -> Ok `Done
    | `String "preview" -> Ok `Preview
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Apply_auto_approve -> `String "apply-auto-approve"
    | `Commit -> `String "commit"
    | `Done -> `String "done"
    | `Preview -> `String "preview"

  type t =
    ([ `Apply_auto_approve
     | `Commit
     | `Done
     | `Preview
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  dwork_id : string;
  type_ : Type.t; [@key "type"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
