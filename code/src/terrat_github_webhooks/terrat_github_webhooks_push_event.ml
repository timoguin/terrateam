type t = {
  after : string;
  installation : Terrat_github_webhooks_installation_lite.t option; [@default None]
  ref_ : string; [@key "ref"]
  repository : Terrat_github_webhooks_repository.t;
  sender : Terrat_github_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
