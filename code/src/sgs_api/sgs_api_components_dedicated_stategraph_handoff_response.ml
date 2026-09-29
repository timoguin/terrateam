type t = { url : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
