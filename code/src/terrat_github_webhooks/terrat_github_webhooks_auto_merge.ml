type t = {
  commit_message : string;
  commit_title : string;
  enabled_by : Terrat_github_webhooks_user.t;
  merge_method : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show]