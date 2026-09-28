module Reasons = struct
  type t = Sgs_capability_denied_reason.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  id : string;
  reasons : Reasons.t;
  truncated : bool;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
