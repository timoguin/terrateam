type t = {
  addresses : Sg_caps_wire_scope.t;
  state : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
