module Primary = struct
  module Notification_setting = struct
    let t_of_yojson = function
      | `String "notifications_disabled" -> Ok `Notifications_disabled
      | `String "notifications_enabled" -> Ok `Notifications_enabled
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Notifications_disabled -> `String "notifications_disabled"
      | `Notifications_enabled -> `String "notifications_enabled"

    type t =
      ([ `Notifications_disabled
       | `Notifications_enabled
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    created_at : string;
    description : string option; [@default None]
    group_id : string option; [@default None]
    group_name : string option; [@default None]
    html_url : string;
    id : int64;
    members_url : string;
    name : string;
    notification_setting : Notification_setting.t option; [@default None]
    organization_selection_type : string option; [@default None]
    slug : string;
    sync_to_organizations : string option; [@default None]
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
