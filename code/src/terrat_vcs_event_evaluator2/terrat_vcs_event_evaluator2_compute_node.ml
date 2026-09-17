module Merge_steps = Terrat_vcs_event_evaluator2_merge_steps
module Tjc = Terrat_job_context
module Wm = Terrat_work_manifest3

(* The workspaces a work manifest asks a run to do.  A step that prepares a job
   has none, so it never spends the budget of a node. *)
let workspaces_of { Wm.changes; _ } = CCList.length changes
let max_work_manifests_per_compute_node = 9

let capabilities_of
    ~max_workspaces
    ({ Wm.branch_ref; environment; runs_on; steps; _ } as work_manifest) =
  {
    Tjc.Compute_node.Capabilities.flags = [];
    sha = branch_ref;
    environment;
    runs_on;
    max_workspaces;
    used_workspaces = workspaces_of work_manifest;
    used_work_manifests = 1;
    merge_phase = Merge_steps.phase_of steps;
  }

let can_run ~merge_steps ~max_workspaces compute_node work_manifest =
  let module C = Tjc.Compute_node in
  let module Cap = C.Capabilities in
  let module Rp = Terrat_vcs_event_evaluator2_batch.Run_params in
  let { Cap.environment; runs_on; used_workspaces; used_work_manifests; merge_phase; _ } =
    compute_node.C.capabilities
  in
  Merge_steps.permits merge_steps ~node_phase:merge_phase work_manifest.Wm.steps
  && compute_node.C.state = C.State.Starting
  && used_work_manifests < max_work_manifests_per_compute_node
  && CCString.equal compute_node.C.capabilities.Cap.sha work_manifest.Wm.branch_ref
  && Rp.equal (environment, runs_on) (work_manifest.Wm.environment, work_manifest.Wm.runs_on)
  &&
  (* The budget is the cap the repo config gives now, and not one the node
     carries.  A node that the steps preparing a job made has no cap, because
     those steps run before there is a config to read, and a plan that joined it
     would then have no bound at all. *)
  match max_workspaces with
  | Some max_workspaces -> used_workspaces + workspaces_of work_manifest <= max_workspaces
  | None -> true
