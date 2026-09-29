type t = { license_key : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
