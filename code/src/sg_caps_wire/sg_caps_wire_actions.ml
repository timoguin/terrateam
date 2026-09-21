type t = {
  modified : Sg_caps_wire_reach.t;
  pulled_in : Sg_caps_wire_reach.t; [@key "pulled-in"]
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
