type t = {
  id : int;
  node_id : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
