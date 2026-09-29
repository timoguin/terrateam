type t = {
  add : int;
  change : int;
  destroy : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
