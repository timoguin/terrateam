type t = {
  lineage : string;
  serial : int;
  terraform_version : string;
  version : int;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
