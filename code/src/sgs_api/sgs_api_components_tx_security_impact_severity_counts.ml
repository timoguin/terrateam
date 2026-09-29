type t = {
  critical : int option; [@default None]
  high : int option; [@default None]
  info : int option; [@default None]
  low : int option; [@default None]
  medium : int option; [@default None]
  unknown : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
