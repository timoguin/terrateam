(** The phase of a work manifest, which is the phase of the compute node made for it.

    A work manifest of no step, or of several, has no phase, and nothing joins a node that has no
    phase. Only [Batch_runs.Merge_steps.By_phase] reads this. *)
val phase_of :
  Terrat_work_manifest3.Step.t list ->
  Terrat_job_context.Compute_node.Capabilities.Merge_phase.t option

(** Whether the configuration permits a step to join an action run that is already going.

    The server puts the steps of a job into as few action runs as it can, because many runs are
    slower than one run. [Batch_runs.Merge_steps] is the limit the user gives it. Four of its values
    make a ladder, and a step above the limit always takes a run of its own. [By_phase] is not on
    that ladder: it permits every step, but only into a run of the same phase, so the setup work and
    the layer work never share a run. [node_phase] is the phase of the run, and a run that has none
    takes nothing.

    This answers for the configuration only. The compute node must be able to take the work as well.
*)
val permits :
  Terrat_base_repo_config_v1.Batch_runs.Merge_steps.t ->
  node_phase:Terrat_job_context.Compute_node.Capabilities.Merge_phase.t option ->
  Terrat_work_manifest3.Step.t list ->
  bool
