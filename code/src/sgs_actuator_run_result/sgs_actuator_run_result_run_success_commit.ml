module Kind = struct
  let t_of_yojson = function
    | `String "success_commit" -> Ok `Success_commit
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Success_commit -> `String "success_commit"

  type t = ([ `Success_commit ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module State = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  kind : Kind.t;
  output : string;
  state : State.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
