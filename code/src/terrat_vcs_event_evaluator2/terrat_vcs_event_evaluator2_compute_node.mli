(** What a compute node can do, and whether it can do one more thing.

    A compute node is one action run. Neither of these answers needs the VCS, so they live apart
    from the state machine that uses them and a test can ask them directly. *)

(** The workspaces a work manifest asks a run to do.

    A step that prepares a job has none, so it never spends the budget of a node. *)
val workspaces_of : ('a, 'b) Terrat_work_manifest3.Existing.t -> int

(** How many work manifests one action run may perform.

    The action stops after eleven turns of its loop, to catch a server that never says done. A node
    that gave out more work than that would leave a work manifest on a run that has gone, and
    nothing would perform it. The chain of layers is what makes that reachable: a job of many layers
    gives a node one work manifest for each of them.

    The server holds the lower bound, so an action of any version is safe. The work manifest over
    the bound takes the normal path and gets a run of its own. *)
val max_work_manifests_per_compute_node : int

(** The capabilities of a node made for one work manifest.

    The node has taken that work manifest, so it is charged for it here. A charge is made when the
    work manifest is given to the node, and not when it runs.

    The phase comes from the work manifest the node is made for, and it stays the same for the life
    of the node: a node that takes a second work manifest writes the record back with this field
    untouched. *)
val capabilities_of :
  max_workspaces:int option ->
  ('a, 'b) Terrat_work_manifest3.Existing.t ->
  Terrat_job_context.Compute_node.Capabilities.t

(** Whether a compute node can run a work manifest.

    A node is one action run. [environment] and [runs_on] are inputs of the workflow dispatch, so
    the VCS fixes them when it schedules the job, and a work manifest that joins the run takes the
    values of the run. They must therefore agree. The refs must agree as well, because one job
    evaluation covers the working branch and the destination branch, and the action of a node has
    one of them checked out.

    [max_workspaces] is the budget of the run, which is the cap of a batch held for the whole run.
    It is the cap the repository configuration gives now, and not one the node carries.

    The three steps that prepare a job pass this test without a special case. They carry no
    environment, no runs_on and no dirspace, so they agree with each other and spend nothing.

    The configuration answers first: [merge_steps] gives the steps that may join a run, and a step
    it does not name always takes a run of its own. *)
val can_run :
  merge_steps:Terrat_base_repo_config_v1.Batch_runs.Merge_steps.t ->
  max_workspaces:int option ->
  Terrat_job_context.Compute_node.t ->
  ('a, 'b) Terrat_work_manifest3.Existing.t ->
  bool
