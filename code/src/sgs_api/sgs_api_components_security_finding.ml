module Blast_radius_modules = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Cross_state_refs = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Internet_reachability_evidence = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  blast_radius_modules : Blast_radius_modules.t option; [@default None]
  blast_radius_resource_count : int option; [@default None]
  check_id : string;
  cross_state_refs : Cross_state_refs.t option; [@default None]
  fingerprint : string;
  first_seen_scan_id : string option; [@default None]
  internet_reachability_evidence : Internet_reachability_evidence.t option; [@default None]
  is_internet_reachable : bool option; [@default None]
  resolved_scan_id : string option; [@default None]
  resource_fq_address : string;
  severity_base : string;
  severity_effective : string;
  severity_reason : string option; [@default None]
  source_end_line : int option; [@default None]
  source_file : string option; [@default None]
  source_start_line : int option; [@default None]
  state_id : string;
  workspace : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
