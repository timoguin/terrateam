type t = {
  email : string;
  name : string;
  organization : string;
  password : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
