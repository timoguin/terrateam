type t = {
  cursor : string option; [@default None]
  limit : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
