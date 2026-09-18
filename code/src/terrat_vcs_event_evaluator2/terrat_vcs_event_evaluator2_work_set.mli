(** The rule that says, for one evaluation of a run, which dirspaces run now.

    A run is a set of dirspaces with an order over them. This module holds the part of that decision
    that depends on nothing but the run, what has been applied, and what the user asked for, so that
    it can be read and tested on its own. Everything around it -- the database, the VCS, access
    control -- stays in the builder tasks. *)

module Op : sig
  (** What the evaluation is for. The job types of the evaluator collapse onto these four, because
      only these four distinctions change the answer. *)
  type t =
    | Apply
        (** An apply or an autoapply. Only this one obeys [apply_after], because only this one
            applies. *)
    | Drift_plan
        (** A drift plan. It plans the whole run in one go and pays no attention to what is applied
            -- a dirspace whose last plan was clean can have drifted since -- with one exception: a
            run in which nothing at all is unapplied runs nothing. *)
    | Explicit_plan
        (** A plan whose tag query names dirspaces, which is what
            {!Terrat_tag_query.selects_dirspaces_only} answers. It selects from the first layer plus
            every applied dirspace of the run, so it reaches a dirspace that a layer selection would
            have dropped. Note this is every applied dirspace and not only the applied members of
            the first layer: an applied dirspace cannot break the order wherever it sits. *)
    | Layer_plan
        (** An autoplan, or a plan whose tag query does not name dirspaces, which includes the empty
            query. It takes the layer that runs next. *)
end

type t = {
  working_set_matches : Terrat_change_match3.Dirspace_config.t list;
      (** What this evaluation runs. *)
  all_unapplied_matches : Terrat_change_match3.Dirspace_config.t list list;
      (** The run that remains, in layers. Empty when the run is over. *)
  working_layer : Terrat_change_match3.Dirspace_config.t list;
      (** The first layer of the run that remains, before the tag query and before [apply_after].
          These are the dirspaces that nothing holds back any more. *)
}

(** Decide what runs now.

    [all_matches] is the whole run. [applied] is what has been applied, which includes a dirspace
    whose last plan found no changes. [dir_exists] answers whether a directory is still in the
    repository; a dirspace reached through an out-of-change apply can name a directory that was
    deleted since, and nothing can be done for it.

    The run that remains is put into layers again rather than keeping the boundaries it started
    with, so a dirspace waits for the dirspaces it depends on and for nothing else. *)
val make :
  config:Terrat_change_match3.Config.t ->
  op:Op.t ->
  tag_query:Terrat_tag_query.t ->
  applied:Terrat_data.Dirspace_set.t ->
  dir_exists:(string -> bool) ->
  all_matches:Terrat_change_match3.Dirspace_config.t list list ->
  t

(** Does the work manifest that just covered [just_ran] leave something that can run now and could
    not before?

    This is the test that decides whether the evaluator starts another round on its own. It asks
    whether the first layer of the run gained a member, not whether [just_ran] and the first layer
    are disjoint: after an apply they are always disjoint, because an applied dirspace has already
    left the run.

    A plan therefore never starts a round of its own -- it leaves every dirspace it planned in the
    run, so the first layer is the one it already planned -- which is what keeps a run that plans
    the same layer over and over from looping.

    [just_ran] must be the work manifests of ONE round, not of the whole run. The evaluator gets
    that by creating a new job for each round and asking for that job's work manifests. A change
    that made a round reuse its predecessor's job would hand this function everything the run has
    ever covered, and the answer would stop meaning anything. *)
val next_round_ready :
  config:Terrat_change_match3.Config.t ->
  all_unapplied_matches:Terrat_change_match3.Dirspace_config.t list list ->
  just_ran:Terrat_dirspace.t list ->
  bool
