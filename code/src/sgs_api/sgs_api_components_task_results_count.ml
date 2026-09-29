type t = { count : int } [@@deriving yojson { strict = false; meta = true }, show, eq]
