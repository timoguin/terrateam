type t = {
  deleted : bool;
  id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
