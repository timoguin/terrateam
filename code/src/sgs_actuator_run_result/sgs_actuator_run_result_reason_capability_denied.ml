module Kind = struct
  let t_of_yojson = function
    | `String "capability_denied" -> Ok `Capability_denied
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Capability_denied -> `String "capability_denied"

  type t = ([ `Capability_denied ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  denied : Sgs_capability_denied_response.t;
  kind : Kind.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
