type t = {
  arn : string;
  resource_type : string;
  service : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
