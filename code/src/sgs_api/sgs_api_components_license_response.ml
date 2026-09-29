type t = { valid : bool } [@@deriving yojson { strict = false; meta = true }, show, eq]
