module Blast_breakdown = struct
  module Items = struct
    type t = {
      bucket : string;
      count : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

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

type t = {
  blast_breakdown : Blast_breakdown.t;
  date : string;
  findings_total_count : int;
  severity_breakdown : Severity_breakdown.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
