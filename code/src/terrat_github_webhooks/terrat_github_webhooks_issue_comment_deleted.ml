module Action = struct
  let t_of_yojson = function
    | `String "deleted" -> Ok `Deleted
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Deleted -> `String "deleted"

  type t = ([ `Deleted ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  action : Action.t;
  comment : Terrat_github_webhooks_issue_comment.t;
  installation : Terrat_github_webhooks_installation_lite.t option; [@default None]
  issue : Terrat_github_webhooks_issue.t;
  repository : Terrat_github_webhooks_repository.t;
  sender : Terrat_github_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
