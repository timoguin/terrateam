type t = {
  email : string option; [@default None]
  id : string;
  is_instance_admin : bool;
  name : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
