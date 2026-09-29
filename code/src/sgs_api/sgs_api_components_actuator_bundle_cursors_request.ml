type t = { limit : int } [@@deriving yojson { strict = false; meta = true }, show, eq]
