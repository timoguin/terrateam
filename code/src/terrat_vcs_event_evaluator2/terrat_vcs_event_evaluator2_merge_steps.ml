module Ms = Terrat_base_repo_config_v1.Batch_runs.Merge_steps
module Step = Terrat_work_manifest3.Step

(* The values make a ladder: each one permits the steps of the one before it, and one step
   more.  A work manifest that holds no step, or more than one, joins nothing: this rule
   answers for one step, and a work manifest that does not have one takes a run of its own. *)
let permits merge_steps = function
  | [ step ] -> (
      match (merge_steps, step) with
      | Ms.None, _ -> false
      | (Ms.Setup | Ms.Setup_and_plan | Ms.All), (Step.Build_tree | Step.Build_config | Step.Index)
        -> true
      | (Ms.Setup_and_plan | Ms.All), Step.Plan -> true
      | Ms.All, (Step.Apply | Step.Unsafe_apply) -> true
      | Ms.Setup, (Step.Plan | Step.Apply | Step.Unsafe_apply) -> false
      | Ms.Setup_and_plan, (Step.Apply | Step.Unsafe_apply) -> false)
  | [] | _ :: _ :: _ -> false
