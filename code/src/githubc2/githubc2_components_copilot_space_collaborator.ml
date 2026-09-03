module V0 = struct
  module All_of = struct
    module Primary = struct
      module Actor_type = struct
        let t_of_yojson = function
          | `String "User" -> Ok `User
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `User -> `String "User"

        type t = ([ `User ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Role = struct
        let t_of_yojson = function
          | `String "admin" -> Ok `Admin
          | `String "reader" -> Ok `Reader
          | `String "writer" -> Ok `Writer
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Admin -> `String "admin"
          | `Reader -> `String "reader"
          | `Writer -> `String "writer"

        type t =
          ([ `Admin
           | `Reader
           | `Writer
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        actor_type : Actor_type.t;
        avatar_url : string;
        email : string option; [@default None]
        events_url : string;
        followers_url : string;
        following_url : string;
        gists_url : string;
        gravatar_id : string option; [@default None]
        html_url : string;
        id : int64;
        login : string;
        name : string option; [@default None]
        node_id : string;
        organizations_url : string;
        received_events_url : string;
        repos_url : string;
        role : Role.t;
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
  end

  module T = struct
    module Primary = struct
      module Actor_type = struct
        let t_of_yojson = function
          | `String "User" -> Ok `User
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `User -> `String "User"

        type t = ([ `User ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Role = struct
        let t_of_yojson = function
          | `String "admin" -> Ok `Admin
          | `String "reader" -> Ok `Reader
          | `String "writer" -> Ok `Writer
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Admin -> `String "admin"
          | `Reader -> `String "reader"
          | `Writer -> `String "writer"

        type t =
          ([ `Admin
           | `Reader
           | `Writer
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        actor_type : Actor_type.t;
        avatar_url : string;
        email : string option; [@default None]
        events_url : string;
        followers_url : string;
        following_url : string;
        gists_url : string;
        gravatar_id : string option; [@default None]
        html_url : string;
        id : int64;
        login : string;
        name : string option; [@default None]
        node_id : string;
        organizations_url : string;
        received_events_url : string;
        repos_url : string;
        role : Role.t;
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
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module V1 = struct
  module Primary = struct
    module Actor_type = struct
      let t_of_yojson = function
        | `String "Team" -> Ok `Team
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `Team -> `String "Team"

      type t = ([ `Team ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Parent = struct
      type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Role = struct
      let t_of_yojson = function
        | `String "admin" -> Ok `Admin
        | `String "reader" -> Ok `Reader
        | `String "writer" -> Ok `Writer
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `Admin -> `String "admin"
        | `Reader -> `String "reader"
        | `Writer -> `String "writer"

      type t =
        ([ `Admin
         | `Reader
         | `Writer
         ]
        [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Type = struct
      let t_of_yojson = function
        | `String "Team" -> Ok `Team
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `Team -> `String "Team"

      type t = ([ `Team ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      actor_type : Actor_type.t;
      description : string option; [@default None]
      html_url : string option; [@default None]
      id : int;
      members_url : string option; [@default None]
      name : string;
      node_id : string;
      notification_setting : string option; [@default None]
      organization_id : int option; [@default None]
      parent : Parent.t option; [@default None]
      privacy : string option; [@default None]
      repositories_url : string option; [@default None]
      role : Role.t;
      slug : string;
      type_ : Type.t; [@key "type"]
      url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t =
  | V0 of V0.t
  | V1 of V1.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.any_of
    (let open CCResult in
     [
       (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
       (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
     ])

let to_yojson = function
  | V0 v -> V0.to_yojson v
  | V1 v -> V1.to_yojson v
