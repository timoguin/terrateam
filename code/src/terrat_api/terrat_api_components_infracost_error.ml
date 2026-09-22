type t = {
  error : string;
  error_code : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
