type t = {
  group_id : int;
  installation_core_id : string;
  name : string;
  state : string;
  webhook_secret : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
