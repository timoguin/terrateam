type t = { path : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
