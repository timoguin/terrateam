module Primary = struct
  module State = struct
    let t_of_yojson = function
      | `String "dismissed" -> Ok `Dismissed
      | `String "open" -> Ok `Open
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Dismissed -> `String "dismissed"
      | `Open -> `String "open"

    type t =
      ([ `Dismissed
       | `Open
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    created_at : string option; [@default None]
    location : Githubc2_components_code_quality_finding_location.t;
    message : Githubc2_components_code_quality_finding_message.t;
    number : int;
    rule : Githubc2_components_code_quality_finding_rule.t;
    state : State.t;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
