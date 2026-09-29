type t = { state_id : string } [@@deriving yojson { strict = false; meta = true }, make, show, eq]
