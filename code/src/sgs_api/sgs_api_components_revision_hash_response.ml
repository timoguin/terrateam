type t = { hash : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
