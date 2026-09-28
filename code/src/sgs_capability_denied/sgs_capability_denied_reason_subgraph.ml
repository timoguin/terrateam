module Kind = struct
  let t_of_yojson = function
    | `String "subgraph" -> Ok `Subgraph
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Subgraph -> `String "subgraph"

  type t = ([ `Subgraph ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  fq_address : string;
  kind : Kind.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
