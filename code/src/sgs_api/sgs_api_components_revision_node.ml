type t = {
  hash : string;
  key : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
