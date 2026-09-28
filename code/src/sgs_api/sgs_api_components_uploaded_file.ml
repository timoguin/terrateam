type t = {
  content : string;
  filepath : string;
  module_ : string; [@key "module"]
  node_id : string;
  state_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
