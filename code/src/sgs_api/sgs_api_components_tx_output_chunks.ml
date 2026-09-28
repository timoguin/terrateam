module Payload = struct
  let t_of_yojson = function
    | `String "apply_stdout" -> Ok `Apply_stdout
    | `String "run_failure" -> Ok `Run_failure
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Apply_stdout -> `String "apply_stdout"
    | `Run_failure -> `String "run_failure"

  type t =
    ([ `Apply_stdout
     | `Run_failure
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Results = struct
  type t = Sgs_api_components_tx_output_chunk.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  payload : Payload.t option; [@default None]
  results : Results.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
