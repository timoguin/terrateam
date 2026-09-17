module Ms = Terrat_base_repo_config_v1.Batch_runs.Merge_steps
module Phase = Terrat_job_context.Compute_node.Capabilities.Merge_phase
module Step = Terrat_work_manifest3.Step

(* The three steps that prepare a job make the setup phase.  A plan and an apply
   make the layer phase, because a chain of layers is what they build. *)
let phase_of_step = function
  | Step.Build_config | Step.Build_tree | Step.Index -> Phase.Setup
  | Step.Apply | Step.Plan | Step.Unsafe_apply -> Phase.Layer

let phase_of = function
  | [ step ] -> Some (phase_of_step step)
  | [] | _ :: _ :: _ -> None

(* [Ms.None], [Ms.Setup], [Ms.Setup_and_plan] and [Ms.All] make a ladder: each one
   permits the steps of the one before it, and one step more.  [Ms.By_phase] is off
   that ladder and asks a different question, so it answers before the rungs.

   A work manifest that holds no step, or more than one, joins nothing: this rule
   answers for one step, and a work manifest that does not have one takes a run of
   its own. *)
let permits merge_steps ~node_phase = function
  | [ step ] -> (
      match (merge_steps, step) with
      | Ms.None, _ -> false
      | Ms.By_phase, _ -> (
          match node_phase with
          | Some node_phase -> Phase.equal (phase_of_step step) node_phase
          | None -> false)
      | (Ms.Setup | Ms.Setup_and_plan | Ms.All), (Step.Build_tree | Step.Build_config | Step.Index)
        -> true
      | (Ms.Setup_and_plan | Ms.All), Step.Plan -> true
      | Ms.All, (Step.Apply | Step.Unsafe_apply) -> true
      | Ms.Setup, (Step.Plan | Step.Apply | Step.Unsafe_apply) -> false
      | Ms.Setup_and_plan, (Step.Apply | Step.Unsafe_apply) -> false)
  | [] | _ :: _ :: _ -> false
