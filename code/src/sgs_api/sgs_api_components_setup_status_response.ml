type t = {
  mode : string option; [@default None]
  needs_setup : bool;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
