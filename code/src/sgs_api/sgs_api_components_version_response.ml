type t = {
  state_schema_version : int;
  version : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
