type t = { window_start : string option [@default None] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
