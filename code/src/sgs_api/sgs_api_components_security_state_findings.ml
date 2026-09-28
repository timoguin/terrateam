module Findings = struct
  type t = Sgs_api_components_security_finding.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  findings : Findings.t;
  limit : int;
  scan : Sgs_api_components_security_scan.t option; [@default None]
  total_count : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
