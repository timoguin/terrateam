(** Whether the configuration permits a step to join an action run that is already going.

    The server puts the steps of a job into as few action runs as it can, because many runs are
    slower than one run. [Batch_runs.Merge_steps] is the limit the user gives it, and a step above
    that limit always takes a run of its own. The compute node must be able to take the work as
    well; this answers for the configuration only. *)
val permits :
  Terrat_base_repo_config_v1.Batch_runs.Merge_steps.t -> Terrat_work_manifest3.Step.t list -> bool
