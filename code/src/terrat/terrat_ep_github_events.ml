module Gw = Githubc2_webhooks

module Sql = struct
  let read fname =
    CCOpt.get_exn_or
      fname
      (CCOpt.map
         (fun s ->
           s
           |> CCString.split_on_char '\n'
           |> CCList.filter CCFun.(CCString.prefix ~pre:"--" %> not)
           |> CCString.concat "\n")
         (Terrat_files_sql.read fname))

  let insert_org =
    Pgsql_io.Typed_sql.(sql // (* id *) Ret.uuid /^ read "insert_org.sql" /% Var.text "name")

  let insert_github_installation =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_installation.sql"
      /% Var.bigint "id"
      /% Var.text "login"
      /% Var.uuid "org"
      /% Var.text "target_type")

  let select_github_installation =
    Pgsql_io.Typed_sql.(
      sql
      // (* id *) Ret.bigint
      /^ "select id from github_installations where id = $id"
      /% Var.bigint "id")

  let insert_github_installation_repository =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_installation_repository.sql"
      /% Var.bigint "id"
      /% Var.bigint "installation_id"
      /% Var.text "owner"
      /% Var.text "name")

  let insert_pull_request =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_github_pull_request.sql"
      /% Var.text "base_branch"
      /% Var.text "base_sha"
      /% Var.text "branch"
      /% Var.bigint "pull_number"
      /% Var.bigint "repository"
      /% Var.text "sha"
      /% Var.(option (text "merged_sha"))
      /% Var.(option (timestamptz "merged_at"))
      /% Var.text "state")

  let insert_dirspace =
    Pgsql_io.Typed_sql.(
      sql
      /^ "insert into github_dirspaces (base_sha, path, repository, sha, workspace) values \
          ($base_sha, $path, $repository, $sha, $workspace) on conflict (repository, sha, path, \
          workspace) do nothing"
      /% Var.text "base_sha"
      /% Var.text "path"
      /% Var.bigint "repository"
      /% Var.text "sha"
      /% Var.text "workspace")

  let insert_work_manifest =
    Pgsql_io.Typed_sql.(
      sql
      // (* id *) Ret.uuid
      // (* state *) Ret.text
      // (* created_at *) Ret.text
      /^ read "insert_github_work_manifest.sql"
      /% Var.text "base_sha"
      /% Var.bigint "pull_number"
      /% Var.bigint "repository"
      /% Var.text "run_type"
      /% Var.text "sha"
      /% Var.text "tag_query")

  let insert_work_manifest_dirspaceflow =
    Pgsql_io.Typed_sql.(
      sql
      /^ "insert into github_work_manifest_dirspaceflows (work_manifest, path, workspace, \
          workflow_idx) values ($work_manifest, $path, $workspace, $workflow_idx)"
      /% Var.uuid "work_manifest"
      /% Var.text "path"
      /% Var.text "workspace"
      /% Var.(option (smallint "workflow_idx")))

  let select_out_of_diff_applies =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workspace *) Ret.text
      /^ read "select_github_out_of_diff_applies.sql"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number")

  let select_running_apply_in_repo =
    Pgsql_io.Typed_sql.(
      sql
      // (* base_hash *) Ret.text
      // (* created_at *) Ret.text
      // (* hash *) Ret.text
      // (* id *) Ret.uuid
      // (* run_id *) Ret.(option text)
      // (* run_type *) Ret.text
      // (* tag_query *) Ret.text
      // (* base_branch *) Ret.text
      // (* branch *) Ret.text
      // (* pull_number *) Ret.bigint
      // (* pr state *) Ret.text
      // (* merged_hash *) Ret.(option text)
      // (* merged_at *) Ret.(option text)
      /^ read "select_github_work_manifest_running_apply_in_repo.sql"
      /% Var.bigint "repository")

  let select_dirspaces_owned_by_other_pull_requests =
    Pgsql_io.Typed_sql.(
      sql
      // (* dir *) Ret.text
      // (* workspace *) Ret.text
      // (* base_branch *) Ret.text
      // (* branch *) Ret.text
      // (* base_hash *) Ret.text
      // (* hash *) Ret.text
      // (* merged_hash *) Ret.(option text)
      // (* merged_at *) Ret.(option text)
      // (* pull_number *) Ret.bigint
      // (* state *) Ret.text
      /^ read "select_github_dirspaces_owned_by_other_pull_requests.sql"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number"
      /% Var.(str_array (text "dirs"))
      /% Var.(str_array (text "workspaces")))

  let select_dirspaces_without_valid_plans =
    Pgsql_io.Typed_sql.(
      sql
      // (* dir *) Ret.text
      // (* workspace *) Ret.text
      /^ read "select_github_dirspaces_without_valid_plans.sql"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number"
      /% Var.(str_array (text "dirs"))
      /% Var.(str_array (text "workspaces")))

  let insert_pull_request_unlock =
    Pgsql_io.Typed_sql.(
      sql
      /^ "insert into github_pull_request_unlocks (repository, pull_number) values ($repository, \
          $pull_number)"
      /% Var.bigint "repository"
      /% Var.bigint "pull_number")

  let fail_running_work_manifest =
    Pgsql_io.Typed_sql.(
      sql
      // (* id *) Ret.uuid
      // (* pull_number *) Ret.bigint
      // (* sha *) Ret.text
      // (* run_type *) Ret.ud' Terrat_work_manifest.Run_type.of_string
      /^ read "github_fail_running_work_manifest.sql"
      /% Var.text "owner"
      /% Var.text "name"
      /% Var.text "run_id")

  let select_missing_dirspace_applies_for_pull_request =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workspace *) Ret.text
      /^ read "select_github_missing_dirspace_applies_for_pull_request.sql"
      /% Var.text "owner"
      /% Var.text "name"
      /% Var.bigint "pull_number")

  let select_work_manifest_dirspaces =
    Pgsql_io.Typed_sql.(
      sql
      // (* path *) Ret.text
      // (* workspace *) Ret.text
      /^ "select path, workspace from github_work_manifest_dirspaceflows where work_manifest = $id"
      /% Var.uuid "id")
end

module Tmpl = struct
  let read fname =
    fname
    |> Terrat_files_tmpl.read
    |> CCOpt.get_exn_or fname
    |> Snabela.Template.of_utf8_string
    |> CCResult.get_exn
    |> fun tmpl -> Snabela.of_template tmpl []

  let missing_plans = read "github_missing_plans.tmpl"

  let dirspaces_owned_by_other_pull_requests =
    read "github_dirspaces_owned_by_other_pull_requests.tmpl"

  let apply_running = read "github_apply_running.tmpl"
  let repo_config_parse_failure = read "github_repo_config_parse_failure.tmpl"
  let repo_config_generic_failure = read "github_repo_config_generic_failure.tmpl"

  let action_failed =
    CCOpt.get_exn_or
      "github_action_failed.tmpl"
      (Terrat_files_tmpl.read "github_action_failed.tmpl")

  let pull_request_not_appliable = read "github_pull_request_not_appliable.tmpl"
  let pull_request_not_mergeable = read "github_pull_request_not_mergeable.tmpl"
  let terrateam_comment_unknown_action = read "terrateam_comment_unknown_action.tmpl"
  let terrateam_comment_help = read "terrateam_comment_help.tmpl"
end

module Event = struct
  type t = {
    access_token : string;
    config : Terrat_config.t;
    installation_id : int;
    pull_number : int;
    repository : Githubc2_webhooks.Repository.t;
    request_id : string;
    run_type : Terrat_work_manifest.Run_type.t;
    tag_query : Terrat_tag_set.t;
  }

  let make
      ~access_token
      ~config
      ~installation_id
      ~pull_number
      ~repository
      ~request_id
      ~run_type
      ~tag_query =
    Logs.info (fun m ->
        m
          "GITHUB_EVENT : %s : MAKE : %s : %s : %d : %s : %s"
          request_id
          repository.Gw.Repository.owner.Gw.User.login
          repository.Gw.Repository.name
          pull_number
          (Terrat_work_manifest.Run_type.to_string run_type)
          (Terrat_tag_set.to_string tag_query));
    {
      access_token;
      config;
      installation_id;
      pull_number;
      repository;
      request_id;
      run_type;
      tag_query;
    }

  let request_id t = t.request_id
  let tag_query t = t.tag_query
  let run_type t = t.run_type
end

let create_check_run event work_manifest changes hash =
  let unified_run_type =
    Terrat_work_manifest.(
      work_manifest.run_type |> Unified_run_type.of_run_type |> Unified_run_type.to_string)
  in
  let target_url =
    Printf.sprintf
      "https://github.com/%s/%s/actions"
      event.Event.repository.Gw.Repository.owner.Gw.User.login
      event.Event.repository.Gw.Repository.name
  in
  let commit_statuses =
    let module T = Terrat_github.Commit_status.Create.T in
    let aggregate =
      T.make
        ~target_url
        ~description:"Queued"
        ~context:(Printf.sprintf "terrateam %s" unified_run_type)
        ~state:"pending"
        ()
    in
    let dirspaces =
      CCList.map
        (fun Terrat_change.{ Dirspaceflow.dirspace = { Dirspace.dir; workspace }; _ } ->
          T.make
            ~target_url
            ~description:"Queued"
            ~context:(Printf.sprintf "terrateam %s %s %s" unified_run_type dir workspace)
            ~state:"pending"
            ())
        changes
    in
    aggregate :: dirspaces
  in
  Terrat_github.Commit_status.create
    ~access_token:event.Event.access_token
    ~owner:event.Event.repository.Gw.Repository.owner.Gw.User.login
    ~repo:event.Event.repository.Gw.Repository.name
    ~sha:hash
    commit_statuses

let diff_of_github_diff =
  CCList.map
    Githubc2_components.Diff_entry.(
      function
      | { primary = { Primary.filename; status = "added" | "copied"; _ }; _ } ->
          Terrat_change.Diff.Add { filename }
      | { primary = { Primary.filename; status = "removed"; _ }; _ } ->
          Terrat_change.Diff.Remove { filename }
      | { primary = { Primary.filename; status = "modified" | "changed" | "unchanged"; _ }; _ } ->
          Terrat_change.Diff.Change { filename }
      | {
          primary =
            { Primary.filename; status = "renamed"; previous_filename = Some previous_filename; _ };
          _;
        } -> Terrat_change.Diff.Move { filename; previous_filename }
      | _ -> failwith "nyi1")

let fetch_diff ~request_id ~access_token ~owner ~repo ~base_sha head_sha =
  let open Abbs_future_combinators.Infix_result_monad in
  Terrat_github.compare_commits ~access_token ~owner ~repo (base_sha, head_sha)
  >>= fun resp ->
  let module Ghc_comp = Githubc2_components in
  let module Cc = Ghc_comp.Commit_comparison in
  match Openapi.Response.value resp with
  | `OK { Cc.primary = { Cc.Primary.files = Some files; _ }; _ } ->
      let diff = diff_of_github_diff files in
      Abb.Future.return (Ok diff)
  | otherwise -> Abb.Future.return (Error (`Bad_compare_response otherwise))

module Evaluator = Terrat_event_evaluator.Make (struct
  module Event = Event

  module Pull_request = struct
    type t = (int64, Terrat_change.Diff.t list, bool) Terrat_pull_request.t

    let base_hash t = t.Terrat_pull_request.base_hash
    let hash t = t.Terrat_pull_request.hash
    let diff t = t.Terrat_pull_request.diff
    let state t = t.Terrat_pull_request.state
    let passed_all_checks t = t.Terrat_pull_request.checks
    let mergeable t = t.Terrat_pull_request.mergeable
  end

  let store_dirspaceflows db event pull_request dirspaceflows =
    let run =
      Abbs_future_combinators.List_result.iter
        ~f:(fun Terrat_change.{ Dirspaceflow.dirspace = { Dirspace.dir; workspace }; _ } ->
          Pgsql_io.Prepared_stmt.execute
            db
            Sql.insert_dirspace
            (Pull_request.base_hash pull_request)
            dir
            (CCInt64.of_int event.Event.repository.Gw.Repository.id)
            (Pull_request.hash pull_request)
            workspace)
        dirspaceflows
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVENT : %s : ERROR : %s" (Event.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let store_pull_request db event pull_request =
    let open Abb.Future.Infix_monad in
    let module Pr = Terrat_pull_request in
    let merged_sha, merged_at, state =
      match pull_request.Pr.state with
      | Pr.State.Open -> (None, None, "open")
      | Pr.State.Closed -> (None, None, "closed")
      | Pr.State.(Merged { Merged.merged_hash; merged_at }) ->
          (Some merged_hash, Some merged_at, "merged")
    in
    Pgsql_io.Prepared_stmt.execute
      db
      Sql.insert_pull_request
      pull_request.Pr.base_branch_name
      pull_request.Pr.base_hash
      pull_request.Pr.branch_name
      pull_request.Pr.id
      (CCInt64.of_int event.Event.repository.Gw.Repository.id)
      pull_request.Pr.hash
      merged_sha
      merged_at
      state
    >>= function
    | Ok () -> Abb.Future.return (Ok ())
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVENT : %s : ERROR : %s" (Event.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let store_new_work_manifest db event work_manifest =
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      let module Wm = Terrat_work_manifest in
      let module Pr = Terrat_pull_request in
      let pull_request = work_manifest.Terrat_work_manifest.pull_request in
      let hash =
        match pull_request.Pr.state with
        | Pr.State.(Merged Merged.{ merged_hash; _ }) -> merged_hash
        | _ -> work_manifest.Wm.hash
      in
      Logs.info (fun m ->
          m
            "GITHUB_EVENT : %s : STORE_WORK_MANIFEST : %s : %s : %Ld : %s : %s"
            (Event.request_id event)
            event.Event.repository.Gw.Repository.owner.Gw.User.login
            event.Event.repository.Gw.Repository.name
            pull_request.Pr.id
            work_manifest.Wm.base_hash
            hash);
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.insert_work_manifest
        ~f:(fun id state created_at -> (id, state, created_at))
        work_manifest.Wm.base_hash
        pull_request.Pr.id
        (CCInt64.of_int event.Event.repository.Gw.Repository.id)
        (Terrat_work_manifest.Run_type.to_string event.Event.run_type)
        hash
        (Terrat_tag_set.to_string work_manifest.Wm.tag_query)
      >>= function
      | [] -> assert false
      | (id, state, created_at) :: _ ->
          Abbs_future_combinators.List_result.iter
            ~f:
              (fun Terrat_change.
                     { Dirspaceflow.dirspace = { Dirspace.dir; workspace }; workflow_idx } ->
              Pgsql_io.Prepared_stmt.execute
                db
                Sql.insert_work_manifest_dirspaceflow
                id
                dir
                workspace
                workflow_idx)
            work_manifest.Wm.changes
          >>= fun () ->
          let wm =
            {
              work_manifest with
              Wm.id;
              state = CCOpt.get_exn_or "work manifest state" (Wm.State.of_string state);
              created_at;
              run_id = None;
              changes = ();
            }
          in
          create_check_run event wm work_manifest.Wm.changes pull_request.Pr.hash
          >>= fun () -> Abb.Future.return (Ok wm)
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok wm -> Abb.Future.return (Ok wm)
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVENT : %s : ERROR : %s" (Event.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)
    | Error (#Githubc2_abb.call_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : ERROR : %s"
              (Event.request_id event)
              (Githubc2_abb.show_call_err err));
        Abb.Future.return (Error `Error)

  let fetch_repo_config event pull_request =
    let open Abb.Future.Infix_monad in
    Terrat_github.fetch_repo_config
      ~python:(Terrat_config.python_exec event.Event.config)
      ~access_token:event.Event.access_token
      ~owner:event.Event.repository.Gw.Repository.owner.Gw.User.login
      ~repo:event.Event.repository.Gw.Repository.name
      pull_request.Terrat_pull_request.branch_name
    >>= function
    | Ok repo_config -> Abb.Future.return (Ok repo_config)
    | Error (`Repo_config_parse_err err) -> Abb.Future.return (Error (`Repo_config_parse_err err))
    (* TODO: Pull these error messages below into something more abstract *)
    | Error `Repo_config_in_sub_module ->
        Abb.Future.return (Error (`Repo_config_err "Repo config in sub module, not supported."))
    | Error `Repo_config_is_symlink ->
        Abb.Future.return (Error (`Repo_config_err "Repo config is a symlink, not supported."))
    | Error `Repo_config_is_dir ->
        Abb.Future.return
          (Error (`Repo_config_err "Repo config is a directory but should be a file."))
    | Error `Repo_config_permission_denied ->
        Abb.Future.return
          (Error (`Repo_config_err "Repo config is inaccessible due to permissions."))
    | Error `Repo_config_unknown_err ->
        Abb.Future.return
          (Error (`Repo_config_err "An unknown error occurred while reading the repo config."))
    | Error (#Terrat_github.fetch_repo_config_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : ERROR : %s"
              (Event.request_id event)
              (Terrat_github.show_fetch_repo_config_err err));
        Abb.Future.return
          (Error (`Repo_config_err "An unknown error occurred while reading the repo config."))

  let fetch_pull_request event =
    let owner = event.Event.repository.Gw.Repository.owner.Gw.User.login in
    let repo = event.Event.repository.Gw.Repository.name in
    let run =
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_github.fetch_pull_request
        ~access_token:event.Event.access_token
        ~owner
        ~repo
        event.Event.pull_number
      >>= fun resp ->
      let module Ghc_comp = Githubc2_components in
      let module Pr = Ghc_comp.Pull_request in
      let module Head = Pr.Primary.Head in
      let module Base = Pr.Primary.Base in
      match Openapi.Response.value resp with
      | `OK
          {
            Ghc_comp.Pull_request.primary =
              {
                Ghc_comp.Pull_request.Primary.head;
                base;
                state;
                merged;
                merged_at;
                merge_commit_sha;
                mergeable_state;
                mergeable;
                _;
              };
            _;
          } ->
          let base_branch_name = Base.(base.primary.Primary.ref_) in
          let base_sha = Base.(base.primary.Primary.sha) in
          let head_sha = Head.(head.primary.Primary.sha) in
          let merged_sha = merge_commit_sha in
          let branch_name = Head.(head.primary.Primary.ref_) in
          fetch_diff
            ~request_id:event.Event.request_id
            ~access_token:event.Event.access_token
            ~owner
            ~repo
            ~base_sha
            head_sha
          >>= fun diff ->
          Abb.Future.return
            (Ok
               Terrat_pull_request.
                 {
                   base_branch_name;
                   base_hash = base_sha;
                   branch_name;
                   diff;
                   hash = head_sha;
                   id = CCInt64.of_int event.Event.pull_number;
                   state =
                     (match (state, merged, merged_sha, merged_at) with
                     | "open", _, _, _ -> State.Open
                     | "closed", true, Some merged_hash, Some merged_at ->
                         State.(Merged Merged.{ merged_hash; merged_at })
                     | "closed", false, _, _ -> State.Closed
                     | _, _, _, _ -> assert false);
                   checks =
                     merged
                     || CCList.mem
                          ~eq:CCString.equal
                          mergeable_state
                          [ "clean"; "unstable"; "has_hooks" ];
                   mergeable;
                 })
      | `Not_found _ | `Internal_server_error _ | `Not_modified -> failwith "nyi2"
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error `Error -> Abb.Future.return (Error `Error)
    | Error (#Githubc2_abb.call_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : ERROR : %s : %s : %s"
              (Event.request_id event)
              owner
              repo
              (Githubc2_abb.show_call_err err));
        Abb.Future.return (Error `Error)
    | Error (#Terrat_github.get_installation_access_token_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : ERROR : %s : %s : %s"
              (Event.request_id event)
              owner
              repo
              (Terrat_github.show_get_installation_access_token_err err));
        Abb.Future.return (Error `Error)
    | Error (`Bad_compare_response (`OK cc)) ->
        Logs.info (fun m ->
            m
              "GITHUB_EVENT : %s : NO_FILES_CHANGED : %s : %s : %d"
              (Event.request_id event)
              owner
              repo
              event.Event.pull_number);
        Logs.info (fun m ->
            m
              "GITHUB_EVENT : %s : NO_FILES_CHANGED : %s : %s : %s"
              (Event.request_id event)
              owner
              repo
              (Githubc2_repos.Compare_commits.Responses.OK.show cc));
        Abb.Future.return (Error `Error)
    | Error (`Bad_compare_response (`Not_found not_found)) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : COMMITS_NOT_FOUND : %s : %s : %d : %s"
              (Event.request_id event)
              owner
              repo
              event.Event.pull_number
              (Githubc2_repos.Compare_commits.Responses.Not_found.show not_found));
        Abb.Future.return (Error `Error)
    | Error (`Bad_compare_response (`Internal_server_error err)) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : INTERNAL_SERVER_ERROR : %s : %s : %d : %s"
              (Event.request_id event)
              owner
              repo
              event.Event.pull_number
              (Githubc2_repos.Compare_commits.Responses.Internal_server_error.show err));
        Abb.Future.return (Error `Error)
    | Error (#Terrat_github.fetch_gitmodules_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : FETCH_GITMODULES : %s : %s : %d : %s"
              (Event.request_id event)
              owner
              repo
              event.Event.pull_number
              (Terrat_github.show_fetch_gitmodules_err err));
        Abb.Future.return (Error `Error)

  let query_pull_request_out_of_diff_applies db event pull_request =
    let run =
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.select_out_of_diff_applies
        ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
        (CCInt64.of_int event.Event.repository.Gw.Repository.id)
        pull_request.Terrat_pull_request.id
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok dirspaces -> Abb.Future.return (Ok dirspaces)
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVENT : %s : ERROR : %s" (Event.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let query_running_apply_in_repo db event =
    let run =
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.select_running_apply_in_repo
        ~f:
          (fun base_hash
               created_at
               hash
               id
               run_id
               run_type
               tag_query
               base_branch
               branch
               pull_number
               pr_state
               merged_hash
               merged_at ->
          let pull_request =
            Terrat_pull_request.
              {
                base_branch_name = base_branch;
                base_hash;
                branch_name = branch;
                diff = [];
                hash;
                id = pull_number;
                state =
                  (match (pr_state, merged_hash, merged_at) with
                  | "open", _, _ -> Terrat_pull_request.State.Open
                  | "closed", _, _ -> Terrat_pull_request.State.Closed
                  | "merged", Some merged_hash, Some merged_at ->
                      Terrat_pull_request.State.(Merged Merged.{ merged_hash; merged_at })
                  | _ -> assert false);
                checks = true;
                mergeable = None;
              }
          in
          Terrat_work_manifest.
            {
              base_hash;
              changes = ();
              completed_at = None;
              created_at;
              hash;
              id;
              pull_request;
              run_id;
              run_type = CCOpt.get_exn_or ("run type " ^ run_type) (Run_type.of_string run_type);
              state = State.Running;
              tag_query = Terrat_tag_set.of_string tag_query;
            })
        (CCInt64.of_int event.Event.repository.Gw.Repository.id)
    in
    let open Abb.Future.Infix_monad in
    run
    >>= function
    | Ok [] -> Abb.Future.return (Ok None)
    | Ok (wm :: _) -> Abb.Future.return (Ok (Some wm))
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVENT : %s : ERROR : %s" (Event.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let query_unapplied_dirspaces db event pull_request =
    let module Pr = Terrat_pull_request in
    let open Abb.Future.Infix_monad in
    Pgsql_io.Prepared_stmt.fetch
      db
      Sql.select_missing_dirspace_applies_for_pull_request
      ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
      event.Event.repository.Gw.Repository.owner.Gw.User.login
      event.Event.repository.Gw.Repository.name
      pull_request.Pr.id
    >>= function
    | Ok dirspaces -> Abb.Future.return (Ok dirspaces)
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVENT : %s : ERROR : %s" (Event.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let query_dirspaces_without_valid_plans db event pull_request dirspaces =
    let open Abb.Future.Infix_monad in
    Pgsql_io.Prepared_stmt.fetch
      db
      ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
      Sql.select_dirspaces_without_valid_plans
      (CCInt64.of_int event.Event.repository.Gw.Repository.id)
      pull_request.Terrat_pull_request.id
      (CCList.map (fun { Terrat_change.Dirspace.dir; _ } -> dir) dirspaces)
      (CCList.map (fun { Terrat_change.Dirspace.workspace; _ } -> workspace) dirspaces)
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVENT : %s : ERROR : %s" (Event.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let query_dirspaces_owned_by_other_pull_requests db event pull_request dirspaces =
    let open Abb.Future.Infix_monad in
    Pgsql_io.Prepared_stmt.fetch
      db
      Sql.select_dirspaces_owned_by_other_pull_requests
      ~f:
        (fun dir workspace base_branch branch base_hash hash merged_hash merged_at pull_number state ->
        ( Terrat_change.Dirspace.{ dir; workspace },
          Terrat_pull_request.
            {
              base_branch_name = base_branch;
              base_hash;
              branch_name = branch;
              diff = [];
              hash;
              id = pull_number;
              state =
                (match (state, merged_hash, merged_at) with
                | "open", _, _ -> Terrat_pull_request.State.Open
                | "closed", _, _ -> Terrat_pull_request.State.Closed
                | "merged", Some merged_hash, Some merged_at ->
                    Terrat_pull_request.State.(Merged Merged.{ merged_hash; merged_at })
                | _ -> assert false);
              checks = true;
              mergeable = None;
            } ))
      (CCInt64.of_int event.Event.repository.Gw.Repository.id)
      pull_request.Terrat_pull_request.id
      (CCList.map (fun { Terrat_change.Dirspace.dir; _ } -> dir) dirspaces)
      (CCList.map (fun { Terrat_change.Dirspace.workspace; _ } -> workspace) dirspaces)
    >>= function
    | Ok res -> Abb.Future.return (Ok (Terrat_event_evaluator.Dirspace_map.of_list res))
    | Error (#Pgsql_io.err as err) ->
        Logs.err (fun m ->
            m "GITHUB_EVENT : %s : ERROR : %s" (Event.request_id event) (Pgsql_io.show_err err));
        Abb.Future.return (Error `Error)

  let publish_comment msg_type event body =
    let open Abb.Future.Infix_monad in
    Terrat_github.publish_comment
      ~access_token:event.Event.access_token
      ~owner:event.Event.repository.Gw.Repository.owner.Gw.User.login
      ~repo:event.Event.repository.Gw.Repository.name
      ~pull_number:event.Event.pull_number
      body
    >>= function
    | Ok () -> Abb.Future.return ()
    | Error (#Terrat_github.publish_comment_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : %s : ERROR : %s"
              (Event.request_id event)
              msg_type
              (Terrat_github.show_publish_comment_err err));
        Abb.Future.return ()

  let apply_template_and_publish msg_type template kv event =
    match Snabela.apply template kv with
    | Ok body -> publish_comment msg_type event body
    | Error (#Snabela.err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVENT : %s : TEMPLATE_ERROR : %s"
              (Event.request_id event)
              (Snabela.show_err err));
        Abb.Future.return ()

  let publish_msg event = function
    | Terrat_event_evaluator.Msg.Missing_plans dirspaces ->
        let kv =
          Snabela.Kv.(
            Map.of_list
              [
                ( "dirspaces",
                  list
                    (CCList.map
                       (fun Terrat_change.Dirspace.{ dir; workspace } ->
                         Map.of_list [ ("dir", string dir); ("workspace", string workspace) ])
                       dirspaces) );
              ])
        in
        CCList.iter
          (fun Terrat_change.Dirspace.{ dir; workspace } ->
            Logs.info (fun m ->
                m
                  "GITHUB_EVENT : %s : MISSING_PLANS : %s : %s"
                  (Event.request_id event)
                  dir
                  workspace))
          dirspaces;
        apply_template_and_publish "MISSING_PLANS" Tmpl.missing_plans kv event
    | Terrat_event_evaluator.Msg.Dirspaces_owned_by_other_pull_request prs ->
        let prs = Terrat_event_evaluator.Dirspace_map.to_list prs in
        let kv =
          Snabela.Kv.(
            Map.of_list
              [
                ( "dirspaces",
                  list
                    (CCList.map
                       (fun ( Terrat_change.Dirspace.{ dir; workspace },
                              Terrat_pull_request.{ id; _ } ) ->
                         Map.of_list
                           [
                             ("dir", string dir);
                             ("workspace", string workspace);
                             ("pull_request_id", string (CCInt64.to_string id));
                           ])
                       prs) );
              ])
        in
        CCList.iter
          (fun (Terrat_change.Dirspace.{ dir; workspace }, Terrat_pull_request.{ id; _ }) ->
            Logs.info (fun m ->
                m
                  "GITHUB_EVENT : %s : DIRSPACES_OWNED_BY_OTHER_PR : %s : %s : %Ld"
                  (Event.request_id event)
                  dir
                  workspace
                  id))
          prs;
        apply_template_and_publish
          "DIRSPACES_OWNED_BY_OTHER_PRS"
          Tmpl.dirspaces_owned_by_other_pull_requests
          kv
          event
    | Terrat_event_evaluator.Msg.Apply_running pull_request ->
        let kv =
          Snabela.Kv.(
            Map.of_list
              [
                ("pull_request_id", string (CCInt64.to_string pull_request.Terrat_pull_request.id));
              ])
        in
        Logs.info (fun m ->
            m
              "GITHUB_EVENT : %s : APPLY_RUNNING : %Ld"
              (Event.request_id event)
              pull_request.Terrat_pull_request.id);
        apply_template_and_publish "APPLY_RUNNING" Tmpl.apply_running kv event
    | Terrat_event_evaluator.Msg.Repo_config_parse_failure err ->
        let kv = Snabela.Kv.(Map.of_list [ ("msg", string err) ]) in
        apply_template_and_publish
          "REPO_CONFIG_PARSE_FAILURE"
          Tmpl.repo_config_parse_failure
          kv
          event
    | Terrat_event_evaluator.Msg.Repo_config_failure err ->
        let kv = Snabela.Kv.(Map.of_list [ ("msg", string err) ]) in
        apply_template_and_publish
          "REPO_CONFIG_GENERIC_FAILURE"
          Tmpl.repo_config_generic_failure
          kv
          event
    | Terrat_event_evaluator.Msg.Pull_request_not_appliable _ ->
        let kv = Snabela.Kv.(Map.of_list []) in
        apply_template_and_publish
          "PULL_REQUEST_NOT_APPLIABLE"
          Tmpl.pull_request_not_appliable
          kv
          event
    | Terrat_event_evaluator.Msg.Pull_request_not_mergeable _ ->
        let kv = Snabela.Kv.(Map.of_list []) in
        apply_template_and_publish
          "PULL_REQUEST_NOT_MERGEABLE"
          Tmpl.pull_request_not_mergeable
          kv
          event
end)

let run_event_evaluator storage event =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.execute
        db
        Sql.insert_github_installation_repository
        (CCInt64.of_int event.Event.repository.Gw.Repository.id)
        (CCInt64.of_int event.Event.installation_id)
        event.Event.repository.Gw.Repository.owner.Gw.User.login
        event.Event.repository.Gw.Repository.name)
  >>= fun () ->
  let open Abb.Future.Infix_monad in
  Evaluator.run storage event
  >>= fun () ->
  Abb.Future.fork (Terrat_github_runner.run (Event.request_id event) event.Event.config storage)
  >>= fun _ -> Abb.Future.return (Ok ())

let perform_unlock_pr config storage installation_id repository pull_number =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.execute
        db
        Sql.insert_pull_request_unlock
        (CCInt64.of_int repository.Gw.Repository.id)
        (CCInt64.of_int pull_number))
  >>= fun () ->
  Terrat_github.get_installation_access_token config installation_id
  >>= fun token ->
  let open Abb.Future.Infix_monad in
  Terrat_github.publish_comment
    ~access_token:token
    ~owner:repository.Gw.Repository.owner.Gw.User.login
    ~repo:repository.Gw.Repository.name
    ~pull_number
    "All directories and workspaces have been unlocked"
  >>= function
  | Ok () -> Abb.Future.return (Ok ())
  | Error (#Terrat_github.publish_comment_err as err) ->
      Logs.err (fun m ->
          m "GITHUB_EVENT : PUBLISH_COMMENT_ERROR : %s" (Terrat_github.show_publish_comment_err err));
      Abb.Future.return (Ok ())

let process_installation request_id config storage = function
  | Gw.Installation_event.Installation_created created ->
      let open Abbs_future_combinators.Infix_result_monad in
      let installation = created.Gw.Installation_created.installation in
      Logs.info (fun m ->
          m
            "INSTALLATION : CREATE :  %d : %s"
            installation.Gw.Installation.id
            created.Gw.Installation_created.installation.Gw.Installation.account.Gw.User.login);
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_github_installation
            ~f:CCFun.id
            (CCInt64.of_int installation.Gw.Installation.id)
          >>= function
          | [] -> (
              Pgsql_io.Prepared_stmt.fetch
                db
                Sql.insert_org
                ~f:CCFun.id
                installation.Gw.Installation.account.Gw.User.login
              >>= function
              | org_id :: _ ->
                  Pgsql_io.Prepared_stmt.execute
                    db
                    Sql.insert_github_installation
                    (Int64.of_int installation.Gw.Installation.id)
                    installation.Gw.Installation.account.Gw.User.login
                    org_id
                    installation.Gw.Installation.account.Gw.User.type_
              | [] -> assert false)
          | _ :: _ -> Abb.Future.return (Ok ()))
  | Gw.Installation_event.Installation_deleted _ -> failwith "nyi6"
  | Gw.Installation_event.Installation_new_permissions_accepted installation_event ->
      let installation = installation_event.Gw.Installation_new_permissions_accepted.installation in
      Logs.info (fun m ->
          m
            "INSTALLATION : ACCEPTED_PERMISSIONS : %d : %s"
            installation.Gw.Installation.id
            installation.Gw.Installation.account.Gw.User.login);
      Abb.Future.return (Ok ())
  | Gw.Installation_event.Installation_suspend _ -> failwith "nyi7"
  | Gw.Installation_event.Installation_unsuspend _ -> failwith "nyi8"

let process_pull_request_event request_id config storage = function
  | Gw.Pull_request_event.Pull_request_opened
      {
        Gw.Pull_request_opened.installation = Some { Gw.Installation_lite.id = installation_id; _ };
        pull_request =
          Gw.Pull_request_opened.Pull_request_.T.
            { primary = Primary.{ number = pull_number; _ }; _ };
        repository;
        _;
      }
  | Gw.Pull_request_event.Pull_request_synchronize
      {
        Gw.Pull_request_synchronize.installation =
          Some { Gw.Installation_lite.id = installation_id; _ };
        repository;
        pull_request = Gw.Pull_request.{ number = pull_number; _ };
        _;
      }
  | Gw.Pull_request_event.Pull_request_reopened
      {
        Gw.Pull_request_reopened.installation =
          Some { Gw.Installation_lite.id = installation_id; _ };
        repository;
        pull_request =
          Gw.Pull_request_reopened.Pull_request_.T.
            { primary = Primary.{ number = pull_number; _ }; _ };
        _;
      } ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_github.get_installation_access_token config installation_id
      >>= fun access_token ->
      let event =
        Event.make
          ~access_token
          ~config
          ~installation_id
          ~pull_number
          ~repository
          ~request_id
          ~run_type:Terrat_work_manifest.Run_type.Autoplan
          ~tag_query:(Terrat_tag_set.of_list [])
      in
      run_event_evaluator storage event
  | Gw.Pull_request_event.Pull_request_opened _ -> failwith "Invalid pull_request_open event"
  | Gw.Pull_request_event.Pull_request_synchronize _ ->
      failwith "Invalid pull_request_synchronize event"
  | Gw.Pull_request_event.Pull_request_reopened _ -> failwith "Invalid pull_request_reopened event"
  | Gw.Pull_request_event.Pull_request_closed
      {
        Gw.Pull_request_closed.installation = Some { Gw.Installation_lite.id = installation_id; _ };
        pull_request =
          Gw.Pull_request_closed.Pull_request_.T.
            { primary = Primary.{ number = pull_number; _ }; _ };
        repository;
        _;
      } ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_github.get_installation_access_token config installation_id
      >>= fun access_token ->
      let event =
        Event.make
          ~access_token
          ~config
          ~installation_id
          ~pull_number
          ~repository
          ~request_id
          ~run_type:Terrat_work_manifest.Run_type.Autoapply
          ~tag_query:(Terrat_tag_set.of_list [])
      in
      run_event_evaluator storage event
  | Gw.Pull_request_event.Pull_request_closed _ -> failwith "Invalid pull_request_closed event"
  | Gw.Pull_request_event.Pull_request_assigned _
  | Gw.Pull_request_event.Pull_request_auto_merge_disabled _
  | Gw.Pull_request_event.Pull_request_auto_merge_enabled _
  | Gw.Pull_request_event.Pull_request_converted_to_draft _
  | Gw.Pull_request_event.Pull_request_edited _
  | Gw.Pull_request_event.Pull_request_labeled _
  | Gw.Pull_request_event.Pull_request_locked _
  | Gw.Pull_request_event.Pull_request_ready_for_review _
  | Gw.Pull_request_event.Pull_request_review_request_removed _
  | Gw.Pull_request_event.Pull_request_review_requested _
  | Gw.Pull_request_event.Pull_request_unassigned _
  | Gw.Pull_request_event.Pull_request_unlabeled _
  | Gw.Pull_request_event.Pull_request_unlocked _ -> failwith "nyi10"

let process_issue_comment request_id config storage = function
  | Gw.Issue_comment_event.Issue_comment_created
      {
        Gw.Issue_comment_created.installation =
          Some { Gw.Installation_lite.id = installation_id; _ };
        repository;
        comment;
        issue =
          Gw.Issue_comment_created.Issue_.T.
            { primary = Primary.{ number = pull_number; pull_request = Some _; _ }; _ };
        _;
      } -> (
      match Terrat_comment.parse comment.Gw.Issue_comment.body with
      | Ok Terrat_comment.Unlock ->
          perform_unlock_pr config storage installation_id repository pull_number
      | Ok (Terrat_comment.Plan { tag_query }) ->
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_github.get_installation_access_token config installation_id
          >>= fun access_token ->
          Terrat_github.react_to_comment
            ~access_token
            ~owner:repository.Gw.Repository.owner.Gw.User.login
            ~repo:repository.Gw.Repository.name
            ~comment_id:comment.Gw.Issue_comment.id
            ()
          >>= fun () ->
          let event =
            Event.make
              ~access_token
              ~config
              ~installation_id
              ~pull_number
              ~repository
              ~request_id
              ~run_type:Terrat_work_manifest.Run_type.Plan
              ~tag_query
          in
          run_event_evaluator storage event
      | Ok (Terrat_comment.Apply { tag_query }) ->
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_github.get_installation_access_token config installation_id
          >>= fun access_token ->
          Terrat_github.react_to_comment
            ~access_token
            ~owner:repository.Gw.Repository.owner.Gw.User.login
            ~repo:repository.Gw.Repository.name
            ~comment_id:comment.Gw.Issue_comment.id
            ()
          >>= fun () ->
          let event =
            Event.make
              ~access_token
              ~config
              ~installation_id
              ~pull_number
              ~repository
              ~request_id
              ~run_type:Terrat_work_manifest.Run_type.Apply
              ~tag_query
          in
          run_event_evaluator storage event
      | Ok Terrat_comment.Help -> (
          let kv = Snabela.Kv.Map.of_list [] in
          match Snabela.apply Tmpl.terrateam_comment_help kv with
          | Ok body ->
              let open Abbs_future_combinators.Infix_result_monad in
              Terrat_github.get_installation_access_token config installation_id
              >>= fun access_token ->
              Terrat_github.publish_comment
                ~access_token
                ~owner:repository.Gw.Repository.owner.Gw.User.login
                ~repo:repository.Gw.Repository.name
                ~pull_number
                body
          | Error (#Snabela.err as err) ->
              Logs.err (fun m ->
                  m "GITHUB_EVENT : %s : TMPL_ERROR : HELP : %s" request_id (Snabela.show_err err));
              Abb.Future.return (Ok ()))
      | Error `Not_terrateam -> Abb.Future.return (Ok ())
      | Error (`Unknown_action action) -> (
          let kv = Snabela.Kv.Map.of_list [] in
          match Snabela.apply Tmpl.terrateam_comment_unknown_action kv with
          | Ok body ->
              let open Abbs_future_combinators.Infix_result_monad in
              Logs.info (fun m ->
                  m "GITHUB_EVENT : %s : COMMENT_ERROR : UNKNOWN_ACTION : %s" request_id action);
              Terrat_github.get_installation_access_token config installation_id
              >>= fun access_token ->
              Terrat_github.publish_comment
                ~access_token
                ~owner:repository.Gw.Repository.owner.Gw.User.login
                ~repo:repository.Gw.Repository.name
                ~pull_number
                body
          | Error (#Snabela.err as err) ->
              Logs.err (fun m ->
                  m
                    "GITHUB_EVENT : %s : TMPL_ERROR : UNKNOWN_ACTION : %s"
                    request_id
                    (Snabela.show_err err));
              Abb.Future.return (Ok ())))
  | Gw.Issue_comment_event.Issue_comment_created _ -> failwith "nyi12"
  | Gw.Issue_comment_event.Issue_comment_deleted _ -> failwith "nyi13"
  | Gw.Issue_comment_event.Issue_comment_edited _ -> failwith "nyi14"

let process_workflow_job_failure storage access_token run_id repository =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      (* Including the repository here just in case run id's are recycled,
         we will limit ourselves to jobs in the correct repository.  Worst
         case is doing something in another customer's repository *)
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.fail_running_work_manifest
        ~f:(fun id pull_number sha run_type -> (id, pull_number, sha, run_type))
        repository.Gw.Repository.owner.Gw.User.login
        repository.Gw.Repository.name
        run_id
      >>= function
      | [] -> Abb.Future.return (Ok None)
      | ((work_manifest_id, pull_number, sha, run_type) as r) :: _ ->
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_work_manifest_dirspaces
            ~f:(fun dir workspace -> Terrat_change.Dirspace.{ dir; workspace })
            work_manifest_id
          >>= fun dirspaces -> Abb.Future.return (Ok (Some (r, dirspaces))))
  >>= function
  | Some ((work_manifest_id, pull_number, sha, run_type), dirspaces) ->
      Logs.info (fun m ->
          m
            "GITHUB_EVENT : WORKFLOW_JOB_FAIL : %s : %s : %Ld"
            repository.Gw.Repository.owner.Gw.User.login
            repository.Gw.Repository.name
            pull_number);
      (* We successfully failed something *)
      Terrat_github.publish_comment
        ~access_token
        ~owner:repository.Gw.Repository.owner.Gw.User.login
        ~repo:repository.Gw.Repository.name
        ~pull_number:(CCInt64.to_int pull_number)
        Tmpl.action_failed
      >>= fun () ->
      let unified_run_type =
        Terrat_work_manifest.(
          run_type |> Unified_run_type.of_run_type |> Unified_run_type.to_string)
      in
      let target_url =
        Printf.sprintf
          "https://github.com/%s/%s/actions/runs/%s"
          repository.Gw.Repository.owner.Gw.User.login
          repository.Gw.Repository.name
          run_id
      in
      let commit_statuses =
        let module T = Terrat_github.Commit_status.Create.T in
        let aggregate =
          T.make
            ~target_url
            ~description:"Failed"
            ~context:(Printf.sprintf "terrateam %s" unified_run_type)
            ~state:"failure"
            ()
        in
        let dirspaces =
          CCList.map
            (fun Terrat_change.Dirspace.{ dir; workspace } ->
              T.make
                ~target_url
                ~description:"Failed"
                ~context:(Printf.sprintf "terrateam %s %s %s" unified_run_type dir workspace)
                ~state:"failure"
                ())
            dirspaces
        in
        aggregate :: dirspaces
      in
      Terrat_github.Commit_status.create
        ~access_token
        ~owner:repository.Gw.Repository.owner.Gw.User.login
        ~repo:repository.Gw.Repository.name
        ~sha
        commit_statuses
  | None ->
      (* Nothing to fail *)
      Logs.warn (fun m ->
          m
            "GITHUB_EVENT : WORKFLOW_JOB_FAIL : NO_MATCHES : %s : %s : %s"
            run_id
            repository.Gw.Repository.owner.Gw.User.login
            repository.Gw.Repository.name);
      Abb.Future.return (Ok ())

let process_workflow_job request_id config storage = function
  | Gw.Workflow_job_event.Workflow_job_completed
      Gw.Workflow_job_completed.
        {
          installation = Some Gw.Installation_lite.{ id = installation_id; _ };
          repository;
          workflow_job =
            Workflow_job_.T.{ primary = Primary.{ run_id; conclusion = Some "failure"; _ }; _ };
          _;
        } ->
      (* We only handle failures specially because only on failure is it possible
         that the action did not communicate back the result to the service. *)
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_github.get_installation_access_token config installation_id
      >>= fun access_token ->
      process_workflow_job_failure storage access_token (CCInt.to_string run_id) repository
  | Gw.Workflow_job_event.Workflow_job_completed _
  | Gw.Workflow_job_event.Workflow_job_in_progress _
  | Gw.Workflow_job_event.Workflow_job_queued _ -> Abb.Future.return (Ok ())

let handle_error ctx = function
  | #Pgsql_pool.err as err ->
      Logs.err (fun m ->
          m "GITHUB_EVENT : %s : ERROR : %s" (Brtl_ctx.token ctx) (Pgsql_pool.show_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | #Pgsql_io.err as err ->
      Logs.err (fun m ->
          m "GITHUB_EVENT : %s : ERROR : %s" (Brtl_ctx.token ctx) (Pgsql_io.show_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | #Terrat_github.get_installation_access_token_err as err ->
      Logs.err (fun m ->
          m
            "GITHUB_EVENT : %s : ERROR : %s"
            (Brtl_ctx.token ctx)
            (Terrat_github.show_get_installation_access_token_err err));
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)
  | #Terrat_github.publish_comment_err as err ->
      Logs.err (fun m ->
          m
            "GITHUB_EVENT : %s : ERROR : %s"
            (Brtl_ctx.token ctx)
            (Terrat_github.show_publish_comment_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
  | `Repo_config_err err ->
      Logs.err (fun m -> m "GITHUB_EVENT : %s : ERROR : REPO_CONFIG : %s" (Brtl_ctx.token ctx) err);
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)
  | #Abb_process.check_output_err as err ->
      Logs.err (fun m ->
          m
            "GITHUB_EVENT : %s : ERROR : %s"
            (Brtl_ctx.token ctx)
            (Abb_process.show_check_output_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)

let process_event_handler config storage ctx f =
  let open Abb.Future.Infix_monad in
  f ()
  >>= function
  | Ok () -> Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
  | Error err -> handle_error ctx err

let post config storage ctx =
  let request = Brtl_ctx.request ctx in
  let headers = Brtl_ctx.Request.headers request in
  let body = Brtl_ctx.body ctx in
  match
    Githubc2_webhooks_decoder.run ?secret:(Terrat_config.github_webhook_secret config) headers body
  with
  | Ok (Gw.Event.Installation_event installation_event) ->
      process_event_handler config storage ctx (fun () ->
          process_installation (Brtl_ctx.token ctx) config storage installation_event)
  | Ok (Gw.Event.Pull_request_event pull_request_event) ->
      process_event_handler config storage ctx (fun () ->
          process_pull_request_event (Brtl_ctx.token ctx) config storage pull_request_event)
  | Ok (Gw.Event.Issue_comment_event event) ->
      process_event_handler config storage ctx (fun () ->
          process_issue_comment (Brtl_ctx.token ctx) config storage event)
  | Ok (Gw.Event.Workflow_job_event event) ->
      process_event_handler config storage ctx (fun () ->
          process_workflow_job (Brtl_ctx.token ctx) config storage event)
  | Ok (Gw.Event.Push_event _) ->
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
  | Ok (Gw.Event.Check_run_event _) | Ok (Gw.Event.Check_suite_event _) ->
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
  | Ok (Gw.Event.Workflow_run_event _) ->
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
  | Ok (Gw.Event.Branch_protection_rule_event _)
  | Ok (Gw.Event.Code_scanning_alert_event _)
  | Ok (Gw.Event.Commit_comment_event _)
  | Ok (Gw.Event.Create_event _)
  | Ok (Gw.Event.Delete_event _)
  | Ok (Gw.Event.Deploy_key_event _)
  | Ok (Gw.Event.Deployment_event _)
  | Ok (Gw.Event.Deployment_status_event _)
  | Ok (Gw.Event.Discussion_event _)
  | Ok (Gw.Event.Discussion_comment_event _)
  | Ok (Gw.Event.Fork_event _)
  | Ok (Gw.Event.Github_app_authorization_event _)
  | Ok (Gw.Event.Gollum_event _)
  | Ok (Gw.Event.Installation_repositories_event _)
  | Ok (Gw.Event.Issues_event _)
  | Ok (Gw.Event.Label_event _)
  | Ok (Gw.Event.Marketplace_purchase_event _)
  | Ok (Gw.Event.Member_event _)
  | Ok (Gw.Event.Membership_event _)
  | Ok (Gw.Event.Meta_event _)
  | Ok (Gw.Event.Milestone_event _)
  | Ok (Gw.Event.Org_block_event _)
  | Ok (Gw.Event.Organization_event _)
  | Ok (Gw.Event.Package_event _)
  | Ok (Gw.Event.Page_build_event _)
  | Ok (Gw.Event.Ping_event _)
  | Ok (Gw.Event.Project_card_event _)
  | Ok (Gw.Event.Project_column_event _)
  | Ok (Gw.Event.Project_event _)
  | Ok (Gw.Event.Projects_v2_item_event _)
  | Ok (Gw.Event.Public_event _)
  | Ok (Gw.Event.Pull_request_review_comment_event _)
  | Ok (Gw.Event.Pull_request_review_event _)
  | Ok (Gw.Event.Pull_request_review_thread_event _)
  | Ok (Gw.Event.Release_event _)
  | Ok (Gw.Event.Repository_dispatch_event _)
  | Ok (Gw.Event.Repository_event _)
  | Ok (Gw.Event.Repository_import_event _)
  | Ok (Gw.Event.Repository_vulnerability_alert_event _)
  | Ok (Gw.Event.Secret_scanning_alert_event _)
  | Ok (Gw.Event.Security_advisory_event _)
  | Ok (Gw.Event.Sponsorship_event _)
  | Ok (Gw.Event.Star_event _)
  | Ok (Gw.Event.Status_event _)
  | Ok (Gw.Event.Team_add_event _)
  | Ok (Gw.Event.Team_event _)
  | Ok (Gw.Event.Watch_event _)
  | Ok (Gw.Event.Workflow_dispatch_event _) -> assert false
  | Error (#Githubc2_webhooks_decoder.err as err) ->
      Logs.warn (fun m ->
          m "GITHUB_EVENT : UNKNOWN_EVENT : %s" (Githubc2_webhooks_decoder.show_err err));
      Abb.Future.return
        (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)