type t = {
  id : string;
  is_instance_admin : bool;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
