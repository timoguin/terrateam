type t = {
  enabled : bool; [@default true]
  provider : string;
  region : string option; [@default None]
  source_uri : string;
  window_months : int; [@default 2]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
