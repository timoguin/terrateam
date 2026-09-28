module Template_vars = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  content : string;
  content_hash : string;
  filepath : string;
  mode : int;
  module_ : string; [@key "module"]
  node_id : string;
  template_vars : Template_vars.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
