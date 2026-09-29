type t = {
  current_password : string option; [@default None]
  new_password : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
