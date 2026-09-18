module Dirspace_map = Terrat_data.Dirspace_map
module Dirspace_set = Terrat_data.Dirspace_set
module Int_map = CCMap.Make (CCInt)

module Run = struct
  type t = {
    sha : string;
    created_at : string;
  }
  [@@deriving eq, ord, show]
end

module Plan = struct
  type t = {
    run : Run.t;
    has_changes : bool;
  }
  [@@deriving eq, show]
end

module Dirspace_state = struct
  type t = {
    dirspace : Terrat_dirspace.t;
    last_plan : Plan.t option;
    last_apply : Run.t option;
  }
  [@@deriving eq, show]
end

module Selection = struct
  type t = {
    to_run : Terrat_dirspace.t list;
    applied : Terrat_dirspace.t list;
  }
  [@@deriving eq, show]
end

(* The number of the layer of each dirspace.  A dirspace which no layer holds is absent, and
   {!layer_of} then gives it the first layer, thus no layer is before it. *)
let index_of_layers layers =
  CCList.foldi
    (fun acc number layer ->
      CCList.fold_left (fun acc dirspace -> Dirspace_map.add dirspace number acc) acc layer)
    Dirspace_map.empty
    layers

let layer_of index dirspace = CCOption.get_or ~default:0 (Dirspace_map.find_opt dirspace index)
let later a b = if CCString.compare a b >= 0 then a else b

(* Each time this dirspace has a run recorded for, whether that run is still good or not.  The
   layer order is about when a run happened, thus a run which the files made out of date still
   counts here. *)
let times_of_state { Dirspace_state.dirspace = _; last_plan; last_apply } =
  CCList.filter_map
    CCFun.id
    [
      CCOption.map
        (fun { Plan.run = { Run.sha = _; created_at }; has_changes = _ } -> created_at)
        last_plan;
      CCOption.map (fun { Run.sha = _; created_at } -> created_at) last_apply;
    ]

(* The most recent run of each layer. *)
let times_of_layers ~index states =
  CCList.fold_left
    (fun acc ({ Dirspace_state.dirspace; last_plan = _; last_apply = _ } as state) ->
      let number = layer_of index dirspace in
      CCList.fold_left
        (fun acc created_at ->
          Int_map.update
            number
            (fun current -> Some (CCOption.map_or ~default:created_at (later created_at) current))
            acc)
        acc
        (times_of_state state))
    Int_map.empty
    states

(* The most recent run of every layer before [number]. *)
let time_before times number =
  times
  |> Int_map.to_list
  |> CCList.filter_map (fun (other, created_at) -> if other < number then Some created_at else None)
  |> function
  | [] -> None
  | created_at :: rest -> Some (CCList.fold_left later created_at rest)

(* The first layer which the force reaches.  A dirspace of [force] which no state holds is not a
   dirspace of this pull request, thus it is ignored. *)
let forced_layer ~index ~force states =
  states
  |> CCList.filter_map (fun { Dirspace_state.dirspace; last_plan = _; last_apply = _ } ->
      if Dirspace_set.mem dirspace force then Some (layer_of index dirspace) else None)
  |> function
  | [] -> None
  | number :: rest -> Some (CCList.fold_left CCInt.min number rest)

let dirspaces_of states =
  states
  |> CCList.map (fun { Dirspace_state.dirspace; last_plan = _; last_apply = _ } -> dirspace)
  |> CCList.sort_uniq ~cmp:Terrat_dirspace.compare

let select ~changed_dirspaces ~force ~superseded ~last_run_failed ~layers states =
  let index = index_of_layers layers in
  let times = times_of_layers ~index states in
  let forced = forced_layer ~index ~force states in
  (* A run is good when its dirspace is neither superseded nor changed since [sha]. *)
  let is_good dirspace { Run.sha; created_at = _ } =
    (not (Dirspace_set.mem dirspace superseded))
    && not (Dirspace_set.mem dirspace (changed_dirspaces sha))
  in
  (* A run of a layer must not be older than a run of a layer before it, or the order of the
     layers is broken and this layer must run again. *)
  let stands_in_layer_order number { Run.sha = _; created_at } =
    CCOption.for_all
      (fun before -> CCString.compare created_at before >= 0)
      (time_before times number)
  in
  (* The plan which still stands, thus the dirspace needs no new one. *)
  let good_plan { Dirspace_state.dirspace; last_plan; last_apply = _ } =
    let number = layer_of index dirspace in
    last_plan
    |> CCOption.map (fun { Plan.run; has_changes = _ } -> run)
    |> CCOption.filter (fun run -> is_good dirspace run && stands_in_layer_order number run)
  in
  (* The run which makes the dirspace applied.  A plan which found no changes counts, because
     there is nothing to apply. *)
  let applied_run ({ Dirspace_state.dirspace; last_plan; last_apply } as state) =
    (* A plan made after the apply is work which nobody applied yet.  A stale apply falls through
       to the test below, thus a newer plan which found no changes still counts as applied. *)
    let stands_after_plan { Run.sha = _; created_at } =
      CCOption.for_all
        (fun { Run.sha = _; created_at = planned_at } ->
          CCString.compare created_at planned_at >= 0)
        (good_plan state)
    in
    last_apply
    |> CCOption.filter (fun run -> is_good dirspace run && stands_after_plan run)
    |> CCOption.or_lazy ~else_:(fun () ->
        last_plan
        |> CCOption.filter (fun { Plan.run; has_changes } ->
            (not has_changes) && is_good dirspace run)
        |> CCOption.map (fun { Plan.run; has_changes = _ } -> run))
  in
  let force_reaches number = CCOption.exists (fun first -> first <= number) forced in
  let is_applied ({ Dirspace_state.dirspace; last_plan = _; last_apply = _ } as state) =
    let number = layer_of index dirspace in
    CCOption.exists
      (fun run -> (not (force_reaches number)) && stands_in_layer_order number run)
      (applied_run state)
  in
  (* [is_applied] comes first, thus a dirspace of one list is never in the other.  The force is
     already outside this test: [force_reaches] takes the applied state away from the layer it
     reaches and from each layer after it. *)
  let must_run ({ Dirspace_state.dirspace; last_plan = _; last_apply = _ } as state) =
    (not (is_applied state))
    && (Dirspace_set.mem dirspace force
       || Dirspace_set.mem dirspace last_run_failed
       || CCOption.is_none (good_plan state))
  in
  {
    Selection.to_run = dirspaces_of (CCList.filter must_run states);
    applied = dirspaces_of (CCList.filter is_applied states);
  }
