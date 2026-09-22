type t = {
  key : string;
  value : string option; [@default None]
  value_regex : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
