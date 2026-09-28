type t = {
  session_token : string;
  success : bool;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
