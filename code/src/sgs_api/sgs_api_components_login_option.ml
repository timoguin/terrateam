type t = {
  display_name : string;
  name : string;
  url : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
