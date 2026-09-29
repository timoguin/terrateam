type t = {
  group_id : int;
  name : string;
  state : string;
  webhook_secret : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
