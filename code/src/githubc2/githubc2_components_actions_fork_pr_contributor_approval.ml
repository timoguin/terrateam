module Primary = struct
  module Approval_policy = struct
    let t_of_yojson = function
      | `String "all_external_contributors" -> Ok `All_external_contributors
      | `String "first_time_contributors" -> Ok `First_time_contributors
      | `String "first_time_contributors_new_to_github" -> Ok `First_time_contributors_new_to_github
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `All_external_contributors -> `String "all_external_contributors"
      | `First_time_contributors -> `String "first_time_contributors"
      | `First_time_contributors_new_to_github -> `String "first_time_contributors_new_to_github"

    type t =
      ([ `All_external_contributors
       | `First_time_contributors
       | `First_time_contributors_new_to_github
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = { approval_policy : Approval_policy.t }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
