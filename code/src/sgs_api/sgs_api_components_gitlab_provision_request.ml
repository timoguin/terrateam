type t = {
  access_token : string;
  group_id : int;
  name : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
