type t = {
  body : string;
  id : int;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
