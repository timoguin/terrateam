type t = { number : int } [@@deriving yojson { strict = false; meta = true }, make, show, eq]
