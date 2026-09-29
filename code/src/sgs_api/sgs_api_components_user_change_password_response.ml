type t = {
  id : string;
  password_changed : bool;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
