type t = {
  at : string;
  message : string option; [@default None]
  status : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
