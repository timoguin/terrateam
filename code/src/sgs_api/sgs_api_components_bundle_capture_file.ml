type t = {
  filepath : string;
  module_ : string; [@key "module"]
  node_id : string;
  sandbox_path : string;
  state_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
