type t = {
  id : string;
  revoked : bool;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
