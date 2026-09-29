type t = {
  email : string option; [@default None]
  is_instance_admin : bool option; [@default None]
  name : string;
  password : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
