type t = { canon : string } [@@deriving yojson { strict = false; meta = true }, make, show, eq]
