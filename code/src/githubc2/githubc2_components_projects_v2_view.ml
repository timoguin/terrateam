module Primary = struct
  module Creator = struct
    module All_of = struct
      module Primary = struct
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
          login : string;
          name : string option; [@default None]
          node_id : string;
          organizations_url : string;
          received_events_url : string;
          repos_url : string;
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
          login : string;
          name : string option; [@default None]
          node_id : string;
          organizations_url : string;
          received_events_url : string;
          repos_url : string;
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

  module Group_by = struct
    type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Layout = struct
    let t_of_yojson = function
      | `String "board" -> Ok `Board
      | `String "roadmap" -> Ok `Roadmap
      | `String "table" -> Ok `Table
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Board -> `String "board"
      | `Roadmap -> `String "roadmap"
      | `Table -> `String "table"

    type t =
      ([ `Board
       | `Roadmap
       | `Table
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Sort_by = struct
    module Items = struct
      module Items = struct
        module V0 = struct
          type t = int [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module V1 = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        type t =
          | V0 of V0.t
          | V1 of V1.t
        [@@deriving show, eq]

        let of_yojson =
          Json_schema.one_of
            (let open CCResult in
             [
               (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
               (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
             ])

        let to_yojson = function
          | V0 v -> V0.to_yojson v
          | V1 v -> V1.to_yojson v
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Vertical_group_by = struct
    type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Visible_fields = struct
    type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    created_at : string;
    creator : Creator.t;
    filter : string option; [@default None]
    group_by : Group_by.t;
    html_url : string;
    id : int;
    layout : Layout.t;
    name : string;
    node_id : string;
    number : int;
    project_url : string;
    sort_by : Sort_by.t;
    updated_at : string;
    vertical_group_by : Vertical_group_by.t;
    visible_fields : Visible_fields.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
