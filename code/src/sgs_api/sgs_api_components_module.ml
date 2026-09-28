type t = {
  instance_count : int;
  name : string;
  resource_count : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
