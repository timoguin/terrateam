module Role = struct
  let t_of_yojson = function
    | `String "admin" -> Ok `Admin
    | `String "member" -> Ok `Member
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Admin -> `String "admin"
    | `Member -> `String "member"

  type t =
    ([ `Admin
     | `Member
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Status = struct
  let t_of_yojson = function
    | `String "accepted" -> Ok `Accepted
    | `String "expired" -> Ok `Expired
    | `String "pending" -> Ok `Pending
    | `String "revoked" -> Ok `Revoked
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Accepted -> `String "accepted"
    | `Expired -> `String "expired"
    | `Pending -> `String "pending"
    | `Revoked -> `String "revoked"

  type t =
    ([ `Accepted
     | `Expired
     | `Pending
     | `Revoked
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  created_at : string;
  delivered : bool option; [@default None]
  email : string;
  expires_at : string;
  id : string;
  invited_by_name : string;
  role : Role.t;
  send_count : int;
  status : Status.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
