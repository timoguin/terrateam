type t =
  | Workflow_step_queued of Terrat_github_webhooks_workflow_step_queued.t
  | Workflow_step_in_progress of Terrat_github_webhooks_workflow_step_in_progress.t
  | Workflow_step_completed of Terrat_github_webhooks_workflow_step_completed.t
[@@deriving show]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
    [
      (fun v ->
        map
          (fun v -> Workflow_step_queued v)
          (Terrat_github_webhooks_workflow_step_queued.of_yojson v));
      (fun v ->
        map
          (fun v -> Workflow_step_in_progress v)
          (Terrat_github_webhooks_workflow_step_in_progress.of_yojson v));
      (fun v ->
        map
          (fun v -> Workflow_step_completed v)
          (Terrat_github_webhooks_workflow_step_completed.of_yojson v));
    ])

let to_yojson = function
  | Workflow_step_queued v -> Terrat_github_webhooks_workflow_step_queued.to_yojson v
  | Workflow_step_in_progress v -> Terrat_github_webhooks_workflow_step_in_progress.to_yojson v
  | Workflow_step_completed v -> Terrat_github_webhooks_workflow_step_completed.to_yojson v