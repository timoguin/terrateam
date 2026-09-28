module Kind = struct
  let t_of_yojson = function
    | `String "success_preview" -> Ok `Success_preview
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Success_preview -> `String "success_preview"

  type t = ([ `Success_preview ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Plan_json = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  has_changes : bool;
  kind : Kind.t;
  plan : string;
  plan_json : Plan_json.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
