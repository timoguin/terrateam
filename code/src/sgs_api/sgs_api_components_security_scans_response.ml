module Scans = struct
  type t = Sgs_api_components_security_scan.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  limit : int;
  scans : Scans.t;
  total_count : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
