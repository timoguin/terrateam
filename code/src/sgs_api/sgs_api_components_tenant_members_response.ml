module Members = struct
  type t = Sgs_api_components_tenant_member.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  has_more : bool;
  limit : int;
  members : Members.t;
  next_cursor : string option; [@default None]
  total_count : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
