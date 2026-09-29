type t = {
  email : string;
  password : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
