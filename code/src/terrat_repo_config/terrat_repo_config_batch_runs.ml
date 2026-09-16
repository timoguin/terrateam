module Merge_steps = struct
  let t_of_yojson = function
    | `String "all" -> Ok `All
    | `String "none" -> Ok `None
    | `String "setup" -> Ok `Setup
    | `String "setup_and_plan" -> Ok `Setup_and_plan
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `All -> `String "all"
    | `None -> `String "none"
    | `Setup -> `String "setup"
    | `Setup_and_plan -> `String "setup_and_plan"

  type t =
    ([ `All
     | `None
     | `Setup
     | `Setup_and_plan
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  enabled : bool; [@default false]
  max_workspaces_per_batch : int; [@default 1]
  merge_steps : Merge_steps.t; [@default `Setup]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
