module Delivery = struct
  let t_of_yojson = function
    | `String "emailed" -> Ok `Emailed
    | `String "inviter_has_no_email" -> Ok `Inviter_has_no_email
    | `String "no_provider_key" -> Ok `No_provider_key
    | `String "not_configured" -> Ok `Not_configured
    | `String "transport_failed" -> Ok `Transport_failed
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Emailed -> `String "emailed"
    | `Inviter_has_no_email -> `String "inviter_has_no_email"
    | `No_provider_key -> `String "no_provider_key"
    | `Not_configured -> `String "not_configured"
    | `Transport_failed -> `String "transport_failed"

  type t =
    ([ `Emailed
     | `Inviter_has_no_email
     | `No_provider_key
     | `Not_configured
     | `Transport_failed
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  delivery : Delivery.t;
  invitation : Sgs_api_components_tenant_invitation.t;
  invite_url : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
