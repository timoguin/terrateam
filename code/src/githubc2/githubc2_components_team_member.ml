module Primary = struct
  module Role = struct
    let t_of_yojson = function
      | `String "maintainer" -> Ok `Maintainer
      | `String "member" -> Ok `Member
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Maintainer -> `String "maintainer"
      | `Member -> `String "member"

    type t =
      ([ `Maintainer
       | `Member
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    avatar_url : string;
    email : string option; [@default None]
    events_url : string;
    followers_url : string;
    following_url : string;
    gists_url : string;
    gravatar_id : string option; [@default None]
    html_url : string;
    id : int64;
    inherited : bool option; [@default None]
    login : string;
    name : string option; [@default None]
    node_id : string;
    organizations_url : string;
    received_events_url : string;
    repos_url : string;
    role : Role.t option; [@default None]
    site_admin : bool;
    starred_at : string option; [@default None]
    starred_url : string;
    subscriptions_url : string;
    type_ : string; [@key "type"]
    url : string;
    user_view_type : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
