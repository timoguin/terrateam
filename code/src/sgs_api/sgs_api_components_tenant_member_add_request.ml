type t = { user_id : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
