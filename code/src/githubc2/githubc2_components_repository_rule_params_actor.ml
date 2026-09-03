module Primary = struct
  module Type = struct
    let t_of_yojson = function
      | `String "IntegrationInstallation" -> Ok `IntegrationInstallation
      | `String "RepositoryRole" -> Ok `RepositoryRole
      | `String "Team" -> Ok `Team
      | `String "User" -> Ok `User
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `IntegrationInstallation -> `String "IntegrationInstallation"
      | `RepositoryRole -> `String "RepositoryRole"
      | `Team -> `String "Team"
      | `User -> `String "User"

    type t =
      ([ `IntegrationInstallation
       | `RepositoryRole
       | `Team
       | `User
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    id : int;
    type_ : Type.t; [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
