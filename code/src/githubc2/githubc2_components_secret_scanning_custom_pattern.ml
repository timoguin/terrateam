module Primary = struct
  module Must_match = struct
    type t = string list option [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Must_not_match = struct
    type t = string list option [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module State = struct
    let t_of_yojson = function
      | `String "published" -> Ok `Published
      | `String "unpublished" -> Ok `Unpublished
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Published -> `String "published"
      | `Unpublished -> `String "unpublished"

    type t =
      ([ `Published
       | `Unpublished
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    created_at : string option; [@default None]
    custom_pattern_version : string option; [@default None]
    end_delimiter : string option; [@default None]
    id : int;
    must_match : Must_match.t option; [@default None]
    must_not_match : Must_not_match.t option; [@default None]
    name : string;
    pattern : string;
    push_protection_enabled : bool;
    slug : string;
    start_delimiter : string option; [@default None]
    state : State.t;
    updated_at : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
