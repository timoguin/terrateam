module Primary = struct
  module State = struct
    let t_of_yojson = function
      | `String "closed" -> Ok `Closed
      | `String "open" -> Ok `Open
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Closed -> `String "closed"
      | `Open -> `String "open"

    type t =
      ([ `Closed
       | `Open
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    closed_at : string option; [@default None]
    created_at : string;
    creator : Githubc2_components_simple_user.t;
    deleted_at : string option; [@default None]
    deleted_by : Githubc2_components_nullable_simple_user.t option; [@default None]
    description : string option; [@default None]
    id : float;
    is_template : bool option; [@default None]
    latest_status_update : Githubc2_components_nullable_projects_v2_status_update.t option;
        [@default None]
    node_id : string;
    number : int;
    owner : Githubc2_components_simple_user.t;
    public : bool;
    short_description : string option; [@default None]
    state : State.t option; [@default None]
    title : string;
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
