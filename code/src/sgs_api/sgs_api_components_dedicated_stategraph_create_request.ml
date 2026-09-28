type t = {
  name : string;
  region : string option; [@default None]
  slug : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
