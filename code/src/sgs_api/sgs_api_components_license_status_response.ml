type t = {
  licensed : bool;
  required : bool;
  source : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
