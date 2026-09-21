module States = struct
  type t = Sg_caps_wire_state_reach.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  states : States.t;
  tenant : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
