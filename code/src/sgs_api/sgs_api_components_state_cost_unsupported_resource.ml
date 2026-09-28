type t = {
  address : string;
  no_price : bool;
  provider : string option; [@default None]
  supported : bool;
  type_ : string; [@key "type"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
