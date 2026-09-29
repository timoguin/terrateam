module Severity_breakdown = struct
  type t = {
    critical : int option; [@default None]
    high : int option; [@default None]
    info : int option; [@default None]
    low : int option; [@default None]
    medium : int option; [@default None]
    unknown : int option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Top_checks = struct
  module Items = struct
    type t = {
      check_id : string;
      count : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  internet_reachable_count : int;
  scan : Sgs_api_components_security_scan.t;
  severity_breakdown : Severity_breakdown.t;
  top_checks : Top_checks.t;
  total : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
