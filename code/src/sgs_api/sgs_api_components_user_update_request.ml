type t = {
  avatar_url : string option; [@default None]
  email : string option; [@default None]
  is_instance_admin : bool option; [@default None]
  name : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
