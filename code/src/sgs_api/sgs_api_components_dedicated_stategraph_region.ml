type t = {
  id : string;
  label : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
