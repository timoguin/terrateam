type t = {
  default_branch : string;
  id : int;
  name : string;
  owner : Terrat_github_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
