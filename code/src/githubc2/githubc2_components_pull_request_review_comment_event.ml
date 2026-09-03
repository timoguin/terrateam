module Primary = struct
  module Comment = struct
    module Primary = struct
      module Links_ = struct
        module Primary = struct
          module Html = struct
            module Primary = struct
              type t = { href : string }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Pull_request_ = struct
            module Primary = struct
              type t = { href : string }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Self = struct
            module Primary = struct
              type t = { href : string }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = {
            html : Html.t;
            pull_request : Pull_request_.t;
            self : Self.t;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Reactions = struct
        module Primary = struct
          type t = {
            plus_one : int option; [@default None] [@key "+1"]
            minus_one : int option; [@default None] [@key "-1"]
            confused : int option; [@default None]
            eyes : int option; [@default None]
            heart : int option; [@default None]
            hooray : int option; [@default None]
            laugh : int option; [@default None]
            rocket : int option; [@default None]
            total_count : int option; [@default None]
            url : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module User = struct
        module Primary = struct
          module Type = struct
            let t_of_yojson = function
              | `String "Bot" -> Ok `Bot
              | `String "Organization" -> Ok `Organization
              | `String "User" -> Ok `User
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            let t_to_yojson = function
              | `Bot -> `String "Bot"
              | `Organization -> `String "Organization"
              | `User -> `String "User"

            type t =
              ([ `Bot
               | `Organization
               | `User
               ]
              [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            avatar_url : string option; [@default None]
            deleted : bool option; [@default None]
            email : string option; [@default None]
            events_url : string option; [@default None]
            followers_url : string option; [@default None]
            following_url : string option; [@default None]
            gists_url : string option; [@default None]
            gravatar_id : string option; [@default None]
            html_url : string option; [@default None]
            id : int64 option; [@default None]
            login : string option; [@default None]
            name : string option; [@default None]
            node_id : string option; [@default None]
            organizations_url : string option; [@default None]
            received_events_url : string option; [@default None]
            repos_url : string option; [@default None]
            site_admin : bool option; [@default None]
            starred_url : string option; [@default None]
            subscriptions_url : string option; [@default None]
            type_ : Type.t option; [@default None] [@key "type"]
            url : string option; [@default None]
            user_view_type : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        links_ : Links_.t; [@key "_links"]
        body : string;
        commit_id : string;
        created_at : string;
        diff_hunk : string;
        html_url : string;
        id : int;
        in_reply_to_id : int option; [@default None]
        node_id : string;
        original_commit_id : string;
        original_position : int;
        path : string;
        position : int option; [@default None]
        pull_request_review_id : int option; [@default None]
        pull_request_url : string;
        reactions : Reactions.t;
        subject_type : string option; [@default None]
        updated_at : string;
        url : string;
        user : User.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : string;
    comment : Comment.t;
    pull_request : Githubc2_components_pull_request_minimal.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
