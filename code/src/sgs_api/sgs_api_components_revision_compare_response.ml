module Node_ids = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { node_ids : Node_ids.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
