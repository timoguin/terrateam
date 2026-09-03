module Primary = struct
  module Code = struct
    let t_of_yojson = function
      | `String "custom_pattern_version_mismatch" -> Ok `Custom_pattern_version_mismatch
      | `String "end_delimiter" -> Ok `End_delimiter
      | `String "invalid" -> Ok `Invalid
      | `String "must_match" -> Ok `Must_match
      | `String "must_not_match" -> Ok `Must_not_match
      | `String "name" -> Ok `Name
      | `String "start_delimiter" -> Ok `Start_delimiter
      | `String "unprocessable" -> Ok `Unprocessable
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Custom_pattern_version_mismatch -> `String "custom_pattern_version_mismatch"
      | `End_delimiter -> `String "end_delimiter"
      | `Invalid -> `String "invalid"
      | `Must_match -> `String "must_match"
      | `Must_not_match -> `String "must_not_match"
      | `Name -> `String "name"
      | `Start_delimiter -> `String "start_delimiter"
      | `Unprocessable -> `String "unprocessable"

    type t =
      ([ `Custom_pattern_version_mismatch
       | `End_delimiter
       | `Invalid
       | `Must_match
       | `Must_not_match
       | `Name
       | `Start_delimiter
       | `Unprocessable
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    code : Code.t option; [@default None]
    message : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
