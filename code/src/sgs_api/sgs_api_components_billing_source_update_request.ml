type t = {
  enabled : bool option; [@default None]
  region : string option; [@default None]
  source_uri : string option; [@default None]
  window_months : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
