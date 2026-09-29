type t = { data : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
