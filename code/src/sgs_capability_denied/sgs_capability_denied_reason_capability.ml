module Kind = struct
  let t_of_yojson = function
    | `String "access-token-create" -> Ok `Access_token_create
    | `String "access-token-refresh" -> Ok `Access_token_refresh
    | `String "admin" -> Ok `Admin
    | `String "commit" -> Ok `Commit
    | `String "identity" -> Ok `Identity
    | `String "preview" -> Ok `Preview
    | `String "sudo" -> Ok `Sudo
    | `String "users-manage" -> Ok `Users_manage
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Access_token_create -> `String "access-token-create"
    | `Access_token_refresh -> `String "access-token-refresh"
    | `Admin -> `String "admin"
    | `Commit -> `String "commit"
    | `Identity -> `String "identity"
    | `Preview -> `String "preview"
    | `Sudo -> `String "sudo"
    | `Users_manage -> `String "users-manage"

  type t =
    ([ `Access_token_create
     | `Access_token_refresh
     | `Admin
     | `Commit
     | `Identity
     | `Preview
     | `Sudo
     | `Users_manage
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  detail : string;
  kind : Kind.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
