type t = {
  token : string;
  user_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
