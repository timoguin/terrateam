module Action = struct
  let t_of_yojson = function
    | `String "review_request_removed" -> Ok `Review_request_removed
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Review_request_removed -> `String "review_request_removed"

  type t = ([ `Review_request_removed ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  action : Action.t;
  installation : Terrat_github_webhooks_installation_lite.t option; [@default None]
  number : int;
  pull_request : Terrat_github_webhooks_pull_request.t;
  repository : Terrat_github_webhooks_repository.t;
  sender : Terrat_github_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
