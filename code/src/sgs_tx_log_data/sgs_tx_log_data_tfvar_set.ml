module Data = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  data : Data.t;
  file : string;
  module_ : string; [@key "module"]
  node_id : string;
  var_address : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
