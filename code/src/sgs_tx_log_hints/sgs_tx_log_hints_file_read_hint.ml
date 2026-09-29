type t = {
  call_key : string;
  canon : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
