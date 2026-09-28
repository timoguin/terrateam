type t = {
  check_id : string;
  fingerprint : string;
  resource_fq_address : string;
  severity_base : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
