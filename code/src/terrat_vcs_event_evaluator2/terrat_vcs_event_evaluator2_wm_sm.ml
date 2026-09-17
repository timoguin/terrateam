module Irm = Abbs_future_combinators.Infix_result_monad
module Tjc = Terrat_job_context

let unreasonable_number_of_aborts = 10

module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) =
struct
  let src = Logs.Src.create ("vcs_event_evaluator2_wm_sm." ^ S.name)

  module Logs = (val Logs.src_log src : Logs.LOG)
  module Merge_steps = Terrat_vcs_event_evaluator2_merge_steps
  module Wm = Terrat_work_manifest3
  module Builder = Terrat_vcs_event_evaluator2_builder.Make (S)
  module Tasks_base = Terrat_vcs_event_evaluator2_tasks_base.Make (S) (Keys)

  let time_it s l f =
    Abbs_time_it.run (fun time -> Logs.info (fun m -> l m (Builder.log_id s) time)) f

  type existing_wm =
    ( S.Api.Account.t,
      (unit S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
    Terrat_work_manifest3.Existing.t
  [@@deriving show]

  let publish_comment' f msg = Tasks_base.publish_comment' f msg

  let create_token installation_id work_manifest_id db =
    let open Abbs_future_combinators.Infix_result_monad in
    Terrat_user.create_system_user
      ~access_token_id:work_manifest_id
      ~capabilities:
        Terrat_user.Capability.
          [
            Installation_id (S.Api.Account.Id.to_string installation_id);
            Kv_store_read;
            Kv_store_write;
          ]
      db
    >>= fun user -> Terrat_user.Token.to_token db user

  let create_token' ~log_id installation_id work_manifest_id db =
    let open Abb.Future.Infix_monad in
    create_token installation_id work_manifest_id db
    >>= function
    | Ok _ as r -> Abb.Future.return r
    | Error (#Terrat_user.Token.to_token_err as err) ->
        Logs.err (fun m -> m "%s : CREATE_TOKEN : %a" log_id Terrat_user.Token.pp_to_token_err err);
        Abbs_future_combinators.return_err (`Msg_err "CREATE_TOKEN")

  let match_tag_queries ~accessor ~changes queries =
    CCList.map
      (fun change ->
        ( change,
          CCList.find_idx
            (fun q -> Terrat_change_match3.match_tag_query ~tag_query:(accessor q) change)
            queries ))
      changes

  let replace_stack_vars vars s = Str_template.apply (CCFun.flip Sln_map.String.find_opt vars) s

  let apply_stack_vars_to_workflow stack workflow =
    let module R = Terrat_base_repo_config_v1 in
    let module E = R.Workflows.Entry in
    let module S = R.Stacks.Stack in
    let {
      E.apply = _;
      engine = _;
      environment;
      integrations = _;
      lock_policy = _;
      plan = _;
      runs_on = _;
      storage = _;
      tag_query = _;
    } =
      workflow
    in
    let open CCResult.Infix in
    CCResult.opt_map (replace_stack_vars stack.S.variables) environment
    >>= fun environment -> Ok { workflow with E.environment }

  let dirspaceflows_of_changes_with_branch_target repo_config changes =
    let module R = Terrat_base_repo_config_v1 in
    let module S = R.Stacks in
    let workflows = R.workflows repo_config in
    CCResult.map_l
      (fun ( {
               Terrat_change_match3.Dirspace_config.dirspace;
               lock_branch_target;
               stack_config = { S.Stack.variables; _ } as stack_config;
               _;
             },
             workflow )
         ->
        let open CCResult.Infix in
        let module Dsf = Terrat_change.Dirspaceflow in
        CCResult.opt_map
          (fun (idx, workflow) ->
            let open CCResult.Infix in
            apply_stack_vars_to_workflow stack_config workflow
            >>= fun workflow -> Ok { Dsf.Workflow.idx; workflow })
          workflow
        >>= fun workflow ->
        Ok { Dsf.dirspace; workflow = (lock_branch_target, workflow); variables = Some variables })
      (match_tag_queries
         ~accessor:(fun { R.Workflows.Entry.tag_query; _ } -> tag_query)
         ~changes
         workflows)

  let strip_lock_branch_target dsfs =
    let module Dsf = Terrat_change.Dirspaceflow in
    CCList.map (fun ({ Dsf.workflow = _, workflow; _ } as dsf) -> { dsf with Dsf.workflow }) dsfs

  let dirspaceflows_of_changes repo_config changes =
    let open CCResult.Infix in
    dirspaceflows_of_changes_with_branch_target repo_config changes
    >>= fun dirspaceflows -> Ok (strip_lock_branch_target dirspaceflows)

  let update_wm_state ~request_id ~name work_manifest_id state db =
    Logs.info (fun m ->
        m
          "%s : WM : UPDATE_STATE : name=%s : wm=%a : state=%s"
          request_id
          name
          Uuidm.pp
          work_manifest_id
          (Terrat_work_manifest3.State.to_string state));
    S.Work_manifest.update_state ~request_id db work_manifest_id state

  let update_run_id s name id run_id db =
    time_it
      s
      (fun m log_id time ->
        m
          "%s : WM : UPDATE_RUN_ID : name=%s : wm=%a : run_id=%s : time=%f"
          log_id
          name
          Uuidm.pp
          id
          run_id
          time)
      (fun () ->
        let open Irm in
        S.Work_manifest.update_run_id ~request_id:(Builder.log_id s) db id run_id
        >>= fun () -> update_wm_state ~request_id:(Builder.log_id s) ~name id Wm.State.Running db)

  let set_work s compute_node_id id response db =
    time_it
      s
      (fun m log_id time ->
        m "%s : WM : SET_WORK : compute_node_id=%a : time=%f" log_id Uuidm.pp compute_node_id time)
      (fun () ->
        S.Job_context.Compute_node.set_work
          ~request_id:(Builder.log_id s)
          ~compute_node_id
          ~work_manifest:id
          db
          response)

  (* Every new work manifest gets a compute node in the state [queued], and a
     row in [compute_node_work] with no work.  The dispatcher starts a node that
     is [queued], and the first poll of the run fills the row.  The database
     chooses the id of the node, so it has nothing to do with the id of the work
     manifest. *)
  (* The workspaces a work manifest asks a run to do.  A step that prepares a job
     has none, so it never spends the budget of a node. *)
  let workspaces_of { Wm.changes; _ } = CCList.length changes

  (* The capabilities of a node made for one work manifest.  The node has taken
     that work manifest, so it is charged for it here.  A charge is made when the
     work manifest is given to the node, and not when it runs. *)
  let capabilities_of ~max_workspaces ({ Wm.branch_ref; environment; runs_on; _ } as work_manifest)
      =
    {
      Tjc.Compute_node.Capabilities.flags = [];
      sha = branch_ref;
      environment;
      runs_on;
      max_workspaces;
      used_workspaces = workspaces_of work_manifest;
    }

  let create_compute_node ~max_workspaces s ({ Wm.id; _ } as work_manifest) db =
    time_it
      s
      (fun m log_id time ->
        m "%s : WM : CREATE_COMPUTE_NODE : work_manifest_id=%a : time=%f" log_id Uuidm.pp id time)
      (fun () ->
        let open Irm in
        S.Job_context.Compute_node.create
          ~request_id:(Builder.log_id s)
          ~capabilities:(capabilities_of ~max_workspaces work_manifest)
          db
        >>= fun { Tjc.Compute_node.id = compute_node_id; _ } ->
        S.Job_context.Compute_node.add_work
          ~request_id:(Builder.log_id s)
          ~compute_node_id
          ~work_manifest:id
          db)

  (* The configuration that the repository holds gives the limit.  A step that
     prepares a job runs before a built configuration exists, thus the built
     configuration cannot give it, and the limit must be the same for each step
     of a job. *)
  let merge_steps_of repo_config =
    let module V1 = Terrat_base_repo_config_v1 in
    (V1.batch_runs repo_config).V1.Batch_runs.merge_steps

  (* Whether a compute node can run a work manifest.

     A node is one action run.  [environment] and [runs_on] are inputs of the
     workflow dispatch, so the VCS fixes them when it schedules the job, and a
     work manifest that joins the run takes the values of the run.  They must
     therefore agree.  [Run_params] already names this pair for a batch, and it
     names the same thing here.

     The budget is the cap of a batch, held for the whole run.  A batch caps one
     work manifest, so a node that ran several would pass that cap.

     The refs must agree as well.  One job evaluation covers the working branch
     and the destination branch, and the action of a node has one of them checked
     out.

     The three steps that prepare a job pass this test without a special case.
     They carry no environment, no runs_on and no dirspace, so they agree with
     each other and spend nothing.

     The configuration answers first.  [merge_steps] gives the highest step that
     may join a run, and a step above that limit always takes a run of its own. *)
  let can_run ~merge_steps ~max_workspaces compute_node work_manifest =
    let module C = Tjc.Compute_node in
    let module Cap = C.Capabilities in
    let module Rp = Terrat_vcs_event_evaluator2_batch.Run_params in
    let { Cap.environment; runs_on; used_workspaces; _ } = compute_node.C.capabilities in
    Merge_steps.permits merge_steps work_manifest.Wm.steps
    && compute_node.C.state = C.State.Starting
    && CCString.equal compute_node.C.capabilities.Cap.sha work_manifest.Wm.branch_ref
    && Rp.equal (environment, runs_on) (work_manifest.Wm.environment, work_manifest.Wm.runs_on)
    &&
    (* The budget is the cap the repo config gives now, and not one the node
       carries.  A node that the steps preparing a job made has no cap, because
       those steps run before there is a config to read, and a plan that joined
       it would then have no bound at all. *)
    match max_workspaces with
    | Some max_workspaces -> used_workspaces + workspaces_of work_manifest <= max_workspaces
    | None -> true

  (* Give a compute node a second work manifest.  Only
     [node_that_can_take_it] may answer for this, because it is what proves the
     node owes nothing.

     The work manifest that ran before this one leaves the state [created] on its
     own.  The [Result] branch of [run] calls [update_state_completed] for it,
     and that write fires the trigger
     [work_manifest_compute_node_work_state_trigger], which moves the row of the
     node out of [created]. *)
  let attach_to_compute_node ~max_workspaces s compute_node ({ Wm.id; _ } as work_manifest) db =
    let module C = Tjc.Compute_node in
    let module Cap = C.Capabilities in
    time_it
      s
      (fun m log_id time ->
        m
          "%s : WM : ATTACH_COMPUTE_NODE : compute_node_id=%a : work_manifest_id=%a : time=%f"
          log_id
          Uuidm.pp
          compute_node.C.id
          Uuidm.pp
          id
          time)
      (fun () ->
        let open Irm in
        S.Job_context.Compute_node.add_work
          ~request_id:(Builder.log_id s)
          ~compute_node_id:compute_node.C.id
          ~work_manifest:id
          db
        >>= fun () ->
        S.Job_context.Compute_node.update_capabilities
          ~request_id:(Builder.log_id s)
          ~compute_node_id:compute_node.C.id
          db
          {
            compute_node.C.capabilities with
            Cap.max_workspaces;
            used_workspaces =
              compute_node.C.capabilities.Cap.used_workspaces + workspaces_of work_manifest;
          })

  (* The compute node of this evaluation, when that node can take this work
     manifest as well.

     Ask the database, and not the node in the store.  That node is a snapshot of
     the transaction that read it, and an evaluation that commits something
     durable runs again in a transaction of its own, so by the time it makes the
     next work manifest the snapshot is a transaction old.  The action polls in
     that gap, and a poll that finds the node owes nothing and its work manifest
     is over ends the node.  A work manifest that joined on the snapshot would
     join a run that has gone, and nothing would ever perform it.

     A node owes one work manifest at a time.  The index
     [compute_node_work_wm_state_idx] permits one row in the state [created] for
     each node, so a second row raises a unique violation and fails the whole
     transaction.  The read of the outstanding row is what keeps that from
     happening.  It sees the rows of this transaction as well, so one create that
     makes a work manifest for each batch also gives at most one of them to the
     node. *)
  let node_that_can_take_it ~merge_steps ~max_workspaces s compute_node work_manifest db =
    let module C = Tjc.Compute_node in
    let open Irm in
    match compute_node with
    | Some { C.id = compute_node_id; _ } -> (
        S.Job_context.Compute_node.query ~request_id:(Builder.log_id s) ~compute_node_id db
        >>= function
        | Some compute_node when can_run ~merge_steps ~max_workspaces compute_node work_manifest
          -> (
            S.Job_context.Compute_node.query_work ~request_id:(Builder.log_id s) ~compute_node_id db
            >>| function
            | Some _ -> None
            | None -> Some compute_node)
        | Some _ | None -> Abbs_future_combinators.return_ok None)
    | None -> Abbs_future_combinators.return_ok None

  (* Give each new work manifest a compute node.  A work manifest joins the
     compute node of this evaluation when that node can take it, and gets a node
     of its own when it cannot. *)
  let make_compute_nodes ~compute_node ~merge_steps ~max_workspaces s wms db =
    let open Irm in
    Abbs_future_combinators.List_result.iter
      ~f:(fun wm ->
        node_that_can_take_it ~merge_steps ~max_workspaces s compute_node wm db
        >>= function
        | Some compute_node -> attach_to_compute_node ~max_workspaces s compute_node wm db
        | None -> create_compute_node ~max_workspaces s wm db)
      wms

  let update_state_completed s name work_manifest_id db =
    time_it
      s
      (fun m log_id time ->
        m
          "%s : WM : UPDATE_STATE : COMPLETED : wm=%a : time=%f"
          log_id
          Uuidm.pp
          work_manifest_id
          time)
      (fun () ->
        update_wm_state ~request_id:(Builder.log_id s) ~name work_manifest_id Wm.State.Completed db)

  let query_work_manifests s job_id db =
    time_it
      s
      (fun m log_id time ->
        m "%s : JOB : QUERY_WORK_MANIFESTS : job_id=%a : time=%f" log_id Uuidm.pp job_id time)
      (fun () ->
        S.Job_context.Job.query_work_manifests ~request_id:(Builder.log_id s) db ~job_id ())

  let add_work_manifests s job_id wms db =
    time_it
      s
      (fun m log_id time ->
        m "%s : JOB : ADD_WORK_MANIFESTS : job_id=%a : time=%f" log_id Uuidm.pp job_id time)
      (fun () ->
        Abbs_future_combinators.List_result.iter
          ~f:(fun { Wm.id = work_manifest_id; _ } ->
            S.Job_context.Job.add_work_manifest
              ~request_id:(Builder.log_id s)
              db
              ~job_id
              ~work_manifest_id
              ())
          wms)

  let num_aborts wms =
    CCList.length
    @@ CCList.filter
         (fun { Terrat_work_manifest3.state; _ } -> state = Terrat_work_manifest3.State.Aborted)
         wms

  let too_many_aborts wms = unreasonable_number_of_aborts < num_aborts wms

  let all_wms_completed =
    CCList.for_all (function
      | { Wm.state = Wm.State.Completed; _ } -> true
      | _ -> false)

  let rem_aborted =
    CCList.filter (function
      | { Wm.state = Wm.State.Aborted; _ } -> false
      | _ -> true)

  let publish_fail _s { Builder.Bs.Fetcher.fetch } = function
    | (`Failed_to_start_with_msg_err _ | `Failed_to_start | `Missing_workflow) as err ->
        let open Irm in
        fetch Keys.publish_comment
        >>= fun publish_comment ->
        publish_comment' publish_comment (Terrat_vcs_provider2.Msg.Run_work_manifest_err err)
    | `Job_failed run_id ->
        let open Irm in
        fetch Keys.publish_comment
        >>= fun publish_comment ->
        publish_comment'
          publish_comment
          (Terrat_vcs_provider2.Msg.Work_manifest_run_failed { run_id })
    | `Result_handling_err ->
        (* The evaluation that failed has already published its own message. *)
        Abbs_future_combinators.return_ok ()
    | `Error ->
        (* Dispatching the work manifest failed, so nothing has run and nothing
           else has spoken to the user. *)
        let open Irm in
        fetch Keys.publish_comment
        >>= fun publish_comment ->
        publish_comment'
          publish_comment
          Terrat_vcs_provider2.Msg.(Operation_failed `Work_manifest_start_err)

  let run
      ~name
      ~eq
      ~dest_branch_ref
      ~branch_ref
      ~branch
      ~create
      ~max_workspaces
      ~initiate
      ~fail
      ~result
      s
      ({ Builder.Bs.Fetcher.fetch } as fetcher) =
    let open Irm in
    let module E = Keys.Work_manifest_event in
    Logs.info (fun m -> m "%s : WM : RUN : name=%s" (Builder.log_id s) name);
    fetch Keys.work_manifest_event
    >>= function
    | Some
        (E.Initiate
           {
             work_manifest = { Wm.id; state = Wm.State.(Queued | Running); _ } as work_manifest;
             run_id;
           })
      when eq work_manifest ->
        Logs.info (fun m -> m "%s : WM : INITIATE : name=%s" (Builder.log_id s) name);
        Builder.run_db s ~f:(fun db -> update_run_id s name id run_id db)
        >>= fun () ->
        initiate work_manifest s fetcher
        >>= fun response ->
        fetch Keys.compute_node_id
        >>= fun compute_node_id ->
        (* An initiate event comes from a poll only, and a poll always knows its
           compute node.  Fail loudly if that stops being true. *)
        (match compute_node_id with
          | None -> Abbs_future_combinators.return_err (`Missing_dep_err "compute_node_id")
          | Some compute_node_id ->
              Builder.run_db s ~f:(fun db -> set_work s compute_node_id id response db))
        >>? fun () -> Error (`Suspend_eval name)
    | Some (E.Fail { work_manifest; error }) when eq work_manifest -> (
        Logs.info (fun m -> m "%s : WM : FAIL : name=%s" (Builder.log_id s) name);
        fail work_manifest s fetcher
        >>= fun () ->
        publish_fail s fetcher error
        >>= fun () ->
        fetch Keys.work_manifests_for_job
        >>? function
        | wms when all_wms_completed @@ CCList.filter eq wms -> Ok (CCList.filter eq wms)
        | _ -> Error (`Suspend_eval name))
    | Some (E.Result { work_manifest; result = wm_result }) when eq work_manifest -> (
        Logs.info (fun m -> m "%s : WM : RESULT : name=%s" (Builder.log_id s) name);
        result work_manifest wm_result s fetcher
        >>= fun () ->
        Builder.run_db s ~f:(fun db -> update_state_completed s name work_manifest.Wm.id db)
        >>= fun () ->
        fetch Keys.job
        >>= fun job ->
        (* Explicitly query the work manifests for this job because we might
           have already created work manifests in parallel operations so we
           don't need to do it again. *)
        Builder.run_db s ~f:(fun db -> query_work_manifests s job.Tjc.Job.id db)
        >>? function
        | wms when all_wms_completed @@ CCList.filter eq wms ->
            Logs.info (fun m ->
                m "%s : WM : RESULT : name=%s : all_wms_completed" (Builder.log_id s) name);
            Ok (CCList.filter eq wms)
        | _ ->
            Logs.info (fun m ->
                m "%s : WM : RESULT : name=%s : not_all_wms_completed" (Builder.log_id s) name);
            Error (`Suspend_eval name))
    | Some _ | None -> (
        fetch Keys.job
        >>= fun job ->
        (* Explicitly query the work manifests for this job because we might
           have already created work manifests in parallel operations so we
           don't need to do it again. *)
        Builder.run_db s ~f:(fun db -> query_work_manifests s job.Tjc.Job.id db)
        >>= function
        | wms when too_many_aborts wms ->
            Logs.info (fun m -> m "%s : WM : TOO_MANY_ABORTS" (Builder.log_id s));
            Abbs_future_combinators.return_err (`Compute_aborted_err (num_aborts wms))
        | wms -> (
            match rem_aborted @@ CCList.filter eq wms with
            | [] -> (
                Logs.info (fun m -> m "%s : WM : CREATE : name=%s" (Builder.log_id s) name);
                create ~dest_branch_ref ~branch_ref ~branch s fetcher
                >>= function
                | [] ->
                    Logs.info (fun m ->
                        m "%s : WM : CREATE : name=%s : NO_WORK_MANIFESTS" (Builder.log_id s) name);
                    Abbs_future_combinators.return_ok []
                | wms ->
                    CCList.iter
                      (fun {
                             Terrat_work_manifest3.id;
                             base_ref;
                             branch_ref;
                             environment;
                             runs_on;
                             steps;
                             _;
                           }
                         ->
                        Logs.info (fun m ->
                            m
                              "%s : CREATED_WORK_MANIFEST : id=%a : base_ref=%s : branch_ref=%s : \
                               run_type=%s : env=%s : runs_on=%s"
                              (Builder.log_id s)
                              Uuidm.pp
                              id
                              base_ref
                              branch_ref
                              (CCOption.map_or ~default:"" Wm.Step.to_string
                              @@ CCList.head_opt steps)
                              (CCOption.get_or ~default:"" environment)
                              (CCOption.map_or ~default:"" Yojson.Safe.to_string runs_on)))
                      wms;
                    fetch Keys.job
                    >>= fun job ->
                    Builder.run_db s ~f:(fun db -> add_work_manifests s job.Tjc.Job.id wms db)
                    >>= fun () ->
                    (* Read [Keys.compute_node], and not [Keys.compute_node_id].
                       The server makes these work manifests while it reads the
                       results of a run, and the results entry point adds the
                       node to the store, not its id.

                       Never read the work manifest event here.  The chain of
                       layers evaluates the next layer with no event, and the
                       node of that evaluation must still be able to take it. *)
                    fetch Keys.compute_node
                    >>= fun compute_node ->
                    (* Read the configuration that the repository holds, and
                       not the one that the config builder makes.  A step that
                       prepares a job runs before a built configuration
                       exists. *)
                    fetch Keys.repo_config_raw'
                    >>= fun (_, repo_config_raw) ->
                    (* Ask for the budget only here.  A step that prepares a job
                       runs before there is a repo config to read it from. *)
                    max_workspaces ()
                    >>= fun max_workspaces ->
                    let merge_steps = merge_steps_of repo_config_raw in
                    Builder.run_db s ~f:(fun db ->
                        make_compute_nodes ~compute_node ~merge_steps ~max_workspaces s wms db)
                    >>? fun () -> Error (`Suspend_eval name))
            | wms when all_wms_completed wms ->
                Logs.info (fun m ->
                    m "%s : WM : CREATE : name=%s : all_wms_completed" (Builder.log_id s) name);
                Abbs_future_combinators.return_ok wms
            | _ ->
                Logs.info (fun m ->
                    m "%s : WM : CREATE : name=%s : not_all_wms_completed" (Builder.log_id s) name);
                Abbs_future_combinators.return_err (`Suspend_eval name)))
end
