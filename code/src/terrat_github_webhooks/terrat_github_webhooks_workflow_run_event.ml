type t =
  | Workflow_run_completed of Terrat_github_webhooks_workflow_run_completed.t
  | Workflow_run_requested of Terrat_github_webhooks_workflow_run_requested.t
[@@deriving show]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
    [
      (fun v ->
        map
          (fun v -> Workflow_run_completed v)
          (Terrat_github_webhooks_workflow_run_completed.of_yojson v));
      (fun v ->
        map
          (fun v -> Workflow_run_requested v)
          (Terrat_github_webhooks_workflow_run_requested.of_yojson v));
    ])

let to_yojson = function
  | Workflow_run_completed v -> Terrat_github_webhooks_workflow_run_completed.to_yojson v
  | Workflow_run_requested v -> Terrat_github_webhooks_workflow_run_requested.to_yojson v