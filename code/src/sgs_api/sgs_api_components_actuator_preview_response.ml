type t = {
  has_changes : bool;
  plan : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
