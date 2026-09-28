type t = {
  filepath : string;
  node_id : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
