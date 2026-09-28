type t = {
  canon : string;
  module_ : string; [@key "module"]
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
