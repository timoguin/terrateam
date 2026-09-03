module Base_role = struct
  let t_of_yojson = function
    | `String "admin" -> Ok `Admin
    | `String "no_access" -> Ok `No_access
    | `String "reader" -> Ok `Reader
    | `String "writer" -> Ok `Writer
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Admin -> `String "admin"
    | `No_access -> `String "no_access"
    | `Reader -> `String "reader"
    | `Writer -> `String "writer"

  type t =
    ([ `Admin
     | `No_access
     | `Reader
     | `Writer
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Owner = struct
  type t =
    | Simple_user of Githubc2_components_simple_user.t
    | Organization_simple of Githubc2_components_organization_simple.t
  [@@deriving show, eq]

  let of_yojson =
    Json_schema.any_of
      (let open CCResult in
       [
         (fun v -> map (fun v -> Simple_user v) (Githubc2_components_simple_user.of_yojson v));
         (fun v ->
           map
             (fun v -> Organization_simple v)
             (Githubc2_components_organization_simple.of_yojson v));
       ])

  let to_yojson = function
    | Simple_user v -> Githubc2_components_simple_user.to_yojson v
    | Organization_simple v -> Githubc2_components_organization_simple.to_yojson v
end

module Resources_attributes = struct
  module Items = struct
    module Primary = struct
      module Metadata_ = struct
        module Primary = struct
          type t = {
            copilot_chat_attachment_id : int option; [@default None]
            file_path : string option; [@default None]
            height : int option; [@default None]
            media_type : string option; [@default None]
            name : string option; [@default None]
            number : int option; [@default None]
            repository_id : int option; [@default None]
            text : string option; [@default None]
            url : string option; [@default None]
            width : int option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
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
        copilot_chat_attachment_id : int64 option; [@default None]
        created_at : string option; [@default None]
        id : int64 option; [@default None]
        metadata : Metadata_.t option; [@default None]
        resource_type : Resource_type.t option; [@default None]
        updated_at : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  api_url : string;
  base_role : Base_role.t;
  created_at : string;
  creator : Githubc2_components_simple_user.t;
  description : string option; [@default None]
  general_instructions : string option; [@default None]
  html_url : string;
  id : int64;
  name : string;
  number : int;
  owner : Owner.t;
  resources_attributes : Resources_attributes.t option; [@default None]
  updated_at : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
