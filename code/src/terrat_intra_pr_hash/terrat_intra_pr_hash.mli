(** The rules which decide, on a push to a pull request, which dirspaces must run again and which
    dirspaces keep the result of an earlier run.

    Orchestration connects a run to the head commit sha of a branch. Thus a push makes every
    dirspace of the pull request unapplied and unplanned, although the push can touch one dirspace
    only. These rules replace that sha test with a file test: a dirspace keeps the result of its
    last run while the files which that dirspace uses keep the same hashes.

    The rules are pure. They speak only of dirspaces, runs and layers, thus they need no database
    and no VCS. *)

(** One run of one dirspace, as the database recorded it. *)
module Run : sig
  type t = {
    sha : string;  (** The head commit sha which the run used. *)
    created_at : string;
        (** The time of the work manifest, as [YYYY-MM-DDTHH:MM:SSZ]. The format has a constant
            width, thus a comparison of two of these strings is a comparison of two times. *)
  }
  [@@deriving eq, ord, show]
end

(** One plan of one dirspace. A plan which found no changes makes the dirspace applied, because
    there is nothing to apply. *)
module Plan : sig
  type t = {
    run : Run.t;
    has_changes : bool;
  }
  [@@deriving eq, show]
end

(** What the database knows about one dirspace of the pull request. *)
module Dirspace_state : sig
  type t = {
    dirspace : Terrat_dirspace.t;
    last_plan : Plan.t option;  (** The most recent plan which was a success. *)
    last_apply : Run.t option;  (** The most recent apply which was a success. *)
  }
  [@@deriving eq, show]
end

module Selection : sig
  (** Both lists are in the order of {!Terrat_dirspace.compare} and hold no duplicate, thus the
      result does not change with the order of the input. No dirspace is in both lists, thus the
      caller does not have to know which of them wins. *)
  type t = {
    to_run : Terrat_dirspace.t list;
        (** The dirspaces which must run. A dirspace is here when it has no plan which is still
            good, when its newest run failed, or when the user forced it. A dirspace which counts as
            applied is never here. *)
    applied : Terrat_dirspace.t list;
        (** The dirspaces which count as applied. The caller removes these from the work which is
            left, thus the evaluation stays at the layer which it reached. *)
  }
  [@@deriving eq, show]
end

(** [select ~changed_dirspaces ~force ~superseded ~last_run_failed ~layers states] is the dirspaces
    to run and the dirspaces which count as applied.

    [changed_dirspaces sha] is the set of dirspaces which have at least one file with a different
    hash at [sha] than at the head of the pull request now. The caller makes this set from a
    comparison of the two stored trees, thus the cost is a function of the number of files which
    changed and not of the number of files in the repository.

    [force] is the set of dirspaces which a tag query of an explicit [terrateam plan] comment
    matched. A dirspace of [force] which is not in [states] does nothing: force planning reaches
    only the dirspaces which the pull request changes.

    [superseded] is the set of dirspaces which another pull request applied or merged after every
    run this pull request has for them. No file of this branch records that, thus the file test
    alone cannot find it: the tree of this branch is the same before and after the other pull
    request lands. Such a dirspace has no good run at all, thus it plans again and it counts as
    unapplied.

    [last_run_failed] is the set of dirspaces whose newest run of this pull request was not
    successful. [states] cannot hold that run, because [states] carries the successful runs only,
    thus the newest run [states] knows is the one before the failure. Such a dirspace runs again,
    because the apply gate refuses it for this same reason and there must be one answer. It does not
    touch the applied test: a plan which failed takes nothing away from an apply which succeeded.

    [layers] is the dirspaces of the pull request, in the order in which the layers must run. A
    dirspace which is not in [layers] counts as a dirspace of the first layer.

    A run of a dirspace is good when that dirspace is not in [changed_dirspaces] of the sha of that
    run and not in [superseded]. From this:

    - A dirspace runs when [force] holds it, when [last_run_failed] holds it, or when it has no good
      plan.
    - A dirspace which counts as applied never runs. It has nothing left to do, and this is what
      keeps the two lists apart.
    - A dirspace counts as applied when it has a good apply, or a good plan which found no changes.
    - A good apply counts only when it is not older than the good plan of the same dirspace. A plan
      which is newer than the apply is work which nobody applied yet. Thus the rewind which a force
      starts outlives the evaluation which carries the tag query: [force] is empty again when the
      user applies, but the plan which the force made is still there.
    - A plan and an apply count only when they are not older than each run of each layer before
      them. Thus an explicit run of an early layer makes each later layer plan again and apply
      again.
    - A dirspace counts as applied only when [force] holds no dirspace of its layer or of a layer
      before it. This makes the layers rewind at the moment of the force, before the forced run
      exists. *)
val select :
  changed_dirspaces:(string -> Terrat_data.Dirspace_set.t) ->
  force:Terrat_data.Dirspace_set.t ->
  superseded:Terrat_data.Dirspace_set.t ->
  last_run_failed:Terrat_data.Dirspace_set.t ->
  layers:Terrat_dirspace.t list list ->
  Dirspace_state.t list ->
  Selection.t
