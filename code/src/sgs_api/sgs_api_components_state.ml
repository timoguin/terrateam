type t = {
  created_at : string;
  deleted_at : string option; [@default None]
  deleted_by : string option; [@default None]
  group_id : string;
  id : string;
  name : string;
  workspace : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
