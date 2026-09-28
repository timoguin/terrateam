type t = {
  data : string;
  idx : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
