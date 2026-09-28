module Operation = struct
  let t_of_yojson = function
    | `String "create" -> Ok `Create
    | `String "destroy" -> Ok `Destroy
    | `String "replace" -> Ok `Replace
    | `String "update" -> Ok `Update
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Create -> `String "create"
    | `Destroy -> `String "destroy"
    | `Replace -> `String "replace"
    | `Update -> `String "update"

  type t =
    ([ `Create
     | `Destroy
     | `Replace
     | `Update
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  address : string;
  operation : Operation.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
