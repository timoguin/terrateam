module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) : sig
  module Builder : module type of Terrat_vcs_event_evaluator2_builder.Make (S)

  type existing_wm =
    ( S.Api.Account.t,
      (unit S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
    Terrat_work_manifest3.Existing.t

  val create_token :
    S.Api.Account.Id.t ->
    Uuidm.t ->
    S.Db.t ->
    (string, [> Terrat_user.Token.to_token_err ]) result Abb.Future.t

  (** Same as [create_token] but logs the error and turns it into an internal failure. *)
  val create_token' :
    log_id:string ->
    S.Api.Account.Id.t ->
    Uuidm.t ->
    S.Db.t ->
    (string, [> `Msg_err of string ]) result Abb.Future.t

  val match_tag_queries :
    accessor:('a -> Terrat_tag_query.t) ->
    changes:Terrat_change_match3.Dirspace_config.t list ->
    'a list ->
    (Terrat_change_match3.Dirspace_config.t * (int * 'a) option) list

  val dirspaceflows_of_changes :
    'a Terrat_base_repo_config_v1.t ->
    Terrat_change_match3.Dirspace_config.t list ->
    ( Terrat_change.Dirspaceflow.Workflow.t option Terrat_change.Dirspaceflow.t list,
      [> Str_template.err ] )
    result

  (** Whether the compute node of an evaluation may perform a new work manifest as well, instead of
      that work manifest getting its own node. Asked for one work manifest at a time, from the
      compute node and the work manifest event of the evaluation that makes it. *)
  type reuse_compute_node =
    Terrat_job_context.Compute_node.t option ->
    Keys.Work_manifest_event.t option ->
    existing_wm ->
    Terrat_job_context.Compute_node.t option

  (** Answers no: a new work manifest gets its own compute node, thus its own action run. This is
      the answer for a plan and for an apply, which declare an [environment] and a [runs_on] of
      their own. *)
  val no_compute_node_reuse : reuse_compute_node

  (** Answers yes when the step that just finished on the compute node of this evaluation prepares
      the same job on the same refs, and its run is still going. The steps that prepare a job are
      the tree builder, the config builder and the indexer: each waits for the one before it, they
      read the same checkout, and none of them declares an [environment] or a [runs_on]. *)
  val reuse_after_preparation_step : reuse_compute_node

  val run :
    name:string ->
    eq:(existing_wm -> bool) ->
    dest_branch_ref:S.Api.Ref.t ->
    branch_ref:S.Api.Ref.t ->
    branch:S.Api.Ref.t ->
    create:
      (dest_branch_ref:S.Api.Ref.t ->
      branch_ref:S.Api.Ref.t ->
      branch:S.Api.Ref.t ->
      Builder.B.State.t ->
      Builder.Bs.Fetcher.t ->
      (existing_wm list, Builder.err) result Abb.Future.t) ->
    (* A step that prepares a job passes [reuse_after_preparation_step].  A plan
       and an apply pass [no_compute_node_reuse].  The configuration answers
       first: with [Batch_runs.Merge_steps.None] no work manifest joins a run,
       whatever this function says. *)
    reuse_compute_node:reuse_compute_node ->
    initiate:
      (existing_wm ->
      Builder.B.State.t ->
      Builder.Bs.Fetcher.t ->
      (Terrat_api_components.Work_manifest.t, Builder.err) result Abb.Future.t) ->
    fail:
      (existing_wm ->
      Builder.B.State.t ->
      Builder.Bs.Fetcher.t ->
      (unit, Builder.err) result Abb.Future.t) ->
    result:
      (existing_wm ->
      Terrat_api_components.Work_manifest_result.t ->
      Builder.B.State.t ->
      Builder.Bs.Fetcher.t ->
      (unit, Builder.err) result Abb.Future.t) ->
    Builder.B.State.t ->
    Builder.Bs.Fetcher.t ->
    (existing_wm list, Builder.err) result Abb.Future.t
end
