type t = {
  output_key : string option; [@default None]
  text : string;
}
[@@deriving yojson { strict = true; meta = true }, show]