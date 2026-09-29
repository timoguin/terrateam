type t = {
  access_token : string option; [@default None]
  regenerate_webhook_secret : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
