module Primary = struct
  module Metadata_ = struct
    include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
  end

  module Resource_type = struct
    let t_of_yojson = function
      | `String "free_text" -> Ok `Free_text
      | `String "github_file" -> Ok `Github_file
      | `String "github_issue" -> Ok `Github_issue
      | `String "github_pull_request" -> Ok `Github_pull_request
      | `String "media_content" -> Ok `Media_content
      | `String "repository" -> Ok `Repository
      | `String "uploaded_text_file" -> Ok `Uploaded_text_file
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Free_text -> `String "free_text"
      | `Github_file -> `String "github_file"
      | `Github_issue -> `String "github_issue"
      | `Github_pull_request -> `String "github_pull_request"
      | `Media_content -> `String "media_content"
      | `Repository -> `String "repository"
      | `Uploaded_text_file -> `String "uploaded_text_file"

    type t =
      ([ `Free_text
       | `Github_file
       | `Github_issue
       | `Github_pull_request
       | `Media_content
       | `Repository
       | `Uploaded_text_file
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    copilot_chat_attachment_id : int option; [@default None]
    created_at : string;
    id : int;
    metadata : Metadata_.t;
    resource_type : Resource_type.t;
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
