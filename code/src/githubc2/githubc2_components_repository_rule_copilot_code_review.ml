module Primary = struct
  module Parameters = struct
    module Primary = struct
      type t = {
        review_draft_pull_requests : bool option; [@default None]
        review_on_push : bool option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Type = struct
    let t_of_yojson = function
      | `String "copilot_code_review" -> Ok `Copilot_code_review
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Copilot_code_review -> `String "copilot_code_review"

    type t = ([ `Copilot_code_review ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    parameters : Parameters.t option; [@default None]
    type_ : Type.t; [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
