module Invitations = struct
  type t = Sgs_api_components_tenant_invitation.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  has_more : bool;
  invitations : Invitations.t;
  limit : int;
  next_cursor : string option; [@default None]
  total_count : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
