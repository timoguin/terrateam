type t = {
  removed : bool;
  user_id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
