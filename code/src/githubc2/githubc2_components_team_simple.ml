module Primary = struct
  module Type = struct
    let t_of_yojson = function
      | `String "enterprise" -> Ok `Enterprise
      | `String "organization" -> Ok `Organization
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Enterprise -> `String "enterprise"
      | `Organization -> `String "organization"

    type t =
      ([ `Enterprise
       | `Organization
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    description : string option; [@default None]
    enterprise_id : int option; [@default None]
    html_url : string;
    id : int;
    ldap_dn : string option; [@default None]
    members_url : string;
    name : string;
    node_id : string;
    notification_setting : string option; [@default None]
    organization_id : int option; [@default None]
    permission : string;
    privacy : string option; [@default None]
    repositories_url : string;
    slug : string;
    type_ : Type.t; [@key "type"]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
