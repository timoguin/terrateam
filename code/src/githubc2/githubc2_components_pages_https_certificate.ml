module Primary = struct
  module Domains = struct
    module Items = struct
      type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module State = struct
    let t_of_yojson = function
      | `String "new" -> Ok "new"
      | `String "authorization_created" -> Ok "authorization_created"
      | `String "authorization_pending" -> Ok "authorization_pending"
      | `String "authorized" -> Ok "authorized"
      | `String "authorization_revoked" -> Ok "authorization_revoked"
      | `String "issued" -> Ok "issued"
      | `String "uploaded" -> Ok "uploaded"
      | `String "approved" -> Ok "approved"
      | `String "errored" -> Ok "errored"
      | `String "bad_authz" -> Ok "bad_authz"
      | `String "destroy_pending" -> Ok "destroy_pending"
      | `String "dns_changed" -> Ok "dns_changed"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    description : string;
    domains : Domains.t;
    expires_at : string option; [@default None]
    state : State.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)