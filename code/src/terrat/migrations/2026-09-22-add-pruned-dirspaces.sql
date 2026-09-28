--
-- A dirspace that output pruning removed from a run needs no apply, thus a
-- merged pull request must not keep a lock for it.  RFD 2110.
--
create table pruned_dirspaces (
    created_at timestamp with time zone not null default now(),
    path text not null,
    pull_request uuid not null,
    workspace text not null,
    primary key (path, workspace, pull_request)
);

create index pruned_dirspaces_pull_request_idx
    on pruned_dirspaces (pull_request);

--
-- The lock functions gain one term: a pruned dirspace counts as complete.  The
-- rest of each function is what the locking migrations left.
--
create or replace function update_github_pull_request_dirspace_locks(
    p_repository BIGINT,
    p_pull_number BIGINT
) returns table(
    path text,
    workspace text,
    op text
)
language sql
as $$
    with
-- The dirspaces that output pruning removed from the run of that pull request.
-- They are complete: nothing demands them, thus nobody has to apply them, and a
-- merged pull request must not keep a lock for them.
    pruned_dirspaces_for_pull_request as (
        select
            pd.path,
            pd.workspace
        from pruned_dirspaces as pd
        inner join github_pull_requests_map as prm
            on prm.core_id = pd.pull_request
        where prm.repository_id = \$1 and prm.pull_number = \$2
    ),
-- All dirspaces associated with that pull request
    dirspaces_for_pull_request as (
        select
            gpr.repository,
            gpr.pull_number,
            gcds.path,
            gcds.workspace,
            gcds.lock_policy,
            gcds.branch_target
        from github_pull_requests as gpr
        inner join github_change_dirspaces as gcds
            on gcds.repository = gpr.repository
               and gcds.base_sha = gpr.base_sha
               and gcds.sha = gpr.sha
        where gpr.repository = \$1 and gpr.pull_number = \$2
    ),
-- All dirspace that have been applied for that pull request.  This will only
-- capture applies before the pull request has been merged, because of the inner
-- join with github_change_dirspaces.  A pull request gets a different sha (that
-- of the destination branch HEAD) on post-merge apply.  But that OK beacuse we
-- only need this for finding any applies that were done for commits of the pull
-- request prior to the current commit.  That is, if you have PR1, you did an
-- apply to DS1, then pushed a new commit which reverted DS1, we want to track
-- that you still need to apply DS1 because of that previous commit.
    applied_dirspaces_for_pull_request as (
        select
            gwm.repository,
            gwm.pull_number,
            gcds.path,
            gcds.workspace,
            gcds.lock_policy,
            gcds.branch_target
        from github_work_manifests as gwm
        inner join work_manifest_results as wmr
            on wmr.work_manifest = gwm.id
        inner join github_change_dirspaces as gcds
            on gcds.repository = gwm.repository
               and gcds.base_sha = gwm.base_sha
               and gcds.sha = gwm.sha
               and gcds.path = wmr.path
               and gcds.workspace = wmr.workspace
        where gwm.repository = \$1
              and gwm.pull_number = \$2
              and gwm.run_type in ('autoapply', 'apply')
    ),
-- Now just combine everything and remove dups
    all_dirspaces_for_pull_request as (
        select * from (
            select * from dirspaces_for_pull_request
            union
            select * from applied_dirspaces_for_pull_request
        ) as t
        group by repository, pull_number, path, workspace, lock_policy, branch_target
    ),
-- We need the most recent apply operations for a dirspace.  It is possible that
-- there have been multiple cycles of plans and applies, but we only want to
-- operate on the most recent apply results.
--
-- To note: a plan that has no changes is considered a successful apply.  But it
-- only matters on merge.  So if the pull request is merged, we will include
-- plans.
    latest_applies_for_pull_request as (
        select distinct on (gpr.repository, gpr.pull_number, wmr.path, wmr.workspace)
            wmr.path,
            wmr.workspace,
            wmr.success,
            gwm.run_type,
            (plans.has_changes is null or plans.has_changes) as has_changes,
            gwm.created_at
        from github_pull_requests as gpr
        inner join github_work_manifests as gwm
            on gwm.repository = gpr.repository
               and gwm.pull_number = gpr.pull_number
        inner join work_manifest_results as wmr
            on wmr.work_manifest = gwm.id
        left join plans
            on plans.work_manifest = gwm.id
        where gpr.repository = \$1
              and gpr.pull_number = \$2
              and ((gpr.merged_at is null and gwm.run_type in ('autoapply', 'apply'))
                   or (gpr.merged_at is not null and gwm.run_type in ('autoapply', 'apply', 'autoplan', 'plan')))
        order by gpr.repository, gpr.pull_number, wmr.path, wmr.workspace, gwm.created_at desc
    ),
-- The output of this table is the repository and pull_number if ANY dirspace is
-- not considered complete.  This is really used as a "boolean", because we are
-- narrowing the query to our specific repository and pull request.  So if this
-- table has a row in it, it means we need to insert all of the rows for the
-- dirspaces it owns.  Otherwise if this table is empty, it deletes all rows.
-- This is how we get our "all or nothing" behaviour for locking dirspaces.
    locked as (
        select
            gpr.repository,
            gpr.pull_number
        from github_pull_requests as gpr
        inner join all_dirspaces_for_pull_request as adspr
            on adspr.repository = gpr.repository
               and adspr.pull_number = gpr.pull_number
        left join latest_applies_for_pull_request as lapr
            on lapr.path = adspr.path
               and lapr.workspace = adspr.workspace
        left join github_pull_request_latest_unlocks as unlocks
            on unlocks.repository = gpr.repository
               and unlocks.pull_number = gpr.pull_number
-- If the pull request IS NOT merged then it is locked for this dirspace if
-- there is an apply
        where (gpr.merged_at is null
               and lapr.path is not null
               and lapr.run_type in ('autoapply', 'apply')
               and (unlocks.unlocked_at is null or unlocks.unlocked_at < lapr.created_at))
-- If the pull request IS merged it is locked if there is no apply OR there is
-- an unsuccessful apply or there is a plan that has changes
              or (gpr.merged_at is not null
                  and (unlocks.unlocked_at is null or unlocks.unlocked_at < gpr.merged_at)
                  and adspr.lock_policy in ('strict', 'merge')
                  and not exists (select 1
                                  from pruned_dirspaces_for_pull_request as pdspr
                                  where pdspr.path = adspr.path
                                        and pdspr.workspace = adspr.workspace)
                  and (lapr.path is null
                       or not lapr.success
                       or (lapr.run_type in ('autoplan', 'plan') and lapr.has_changes)))
        group by gpr.repository, gpr.pull_number
    ),
    deleted as (
        delete from dirspace_pull_request_locks as dsprl
        using github_pull_requests_map as gprm
        where gprm.core_id = dsprl.pull_request
              and gprm.repository_id = \$1
              and gprm.pull_number = \$2
              and not exists (select 1 from locked where repository = gprm.repository_id and pull_number = gprm.pull_number)
        returning dsprl.path, dsprl.workspace
    ),
    inserted as (
        insert into dirspace_pull_request_locks (path, workspace, pull_request, branch_target)
        select
            adspr.path,
            adspr.workspace,
            gprm.core_id as pull_request,
            adspr.branch_target
        from locked
        inner join all_dirspaces_for_pull_request as adspr
            on adspr.repository = locked.repository
               and adspr.pull_number = locked.pull_number
        inner join github_pull_requests_map as gprm
            on gprm.repository_id = adspr.repository
               and gprm.pull_number = adspr.pull_number
        on conflict (path, workspace, pull_request) do nothing
        returning path, workspace
    )
    select
        path,
        workspace,
        op
    from (
        select i.path, i.workspace, 'inserted' as op from inserted as i
        union
        select d.path, d.workspace, 'deleted' as op from deleted as d
    )
    as t
$$;

create or replace function update_gitlab_pull_request_dirspace_locks(
    p_repository BIGINT,
    p_pull_number BIGINT
) returns table(
    path text,
    workspace text,
    op text
)
language sql
as $$
    with
-- The dirspaces that output pruning removed from the run of that pull request.
-- They are complete: nothing demands them, thus nobody has to apply them, and a
-- merged pull request must not keep a lock for them.
    pruned_dirspaces_for_pull_request as (
        select
            pd.path,
            pd.workspace
        from pruned_dirspaces as pd
        inner join gitlab_pull_requests_map as prm
            on prm.core_id = pd.pull_request
        where prm.repository_id = \$1 and prm.pull_number = \$2
    ),
-- All dirspaces associated with that pull request
    dirspaces_for_pull_request as (
        select
            gpr.repository,
            gpr.pull_number,
            gcds.path,
            gcds.workspace,
            gcds.lock_policy,
            gcds.branch_target
        from gitlab_pull_requests as gpr
        inner join gitlab_change_dirspaces as gcds
            on gcds.repository = gpr.repository
               and gcds.base_sha = gpr.base_sha
               and gcds.sha = gpr.sha
        where gpr.repository = \$1 and gpr.pull_number = \$2
    ),
-- All dirspace that have been applied for that pull request.  This will only
-- capture applies before the pull request has been merged, because of the inner
-- join with gitlab_change_dirspaces.  A pull request gets a different sha (that
-- of the destination branch HEAD) on post-merge apply.  But that OK beacuse we
-- only need this for finding any applies that were done for commits of the pull
-- request prior to the current commit.  That is, if you have PR1, you did an
-- apply to DS1, then pushed a new commit which reverted DS1, we want to track
-- that you still need to apply DS1 because of that previous commit.
    applied_dirspaces_for_pull_request as (
        select
            gwm.repository,
            gwm.pull_number,
            gcds.path,
            gcds.workspace,
            gcds.lock_policy,
            gcds.branch_target
        from gitlab_work_manifests as gwm
        inner join work_manifest_results as wmr
            on wmr.work_manifest = gwm.id
        inner join gitlab_change_dirspaces as gcds
            on gcds.repository = gwm.repository
               and gcds.base_sha = gwm.base_sha
               and gcds.sha = gwm.sha
               and gcds.path = wmr.path
               and gcds.workspace = wmr.workspace
        where gwm.repository = \$1
              and gwm.pull_number = \$2
              and gwm.run_type in ('autoapply', 'apply')
    ),
-- Now just combine everything and remove dups
    all_dirspaces_for_pull_request as (
        select * from (
            select * from dirspaces_for_pull_request
            union
            select * from applied_dirspaces_for_pull_request
        ) as t
        group by repository, pull_number, path, workspace, lock_policy, branch_target
    ),
-- We need the most recent apply operations for a dirspace.  It is possible that
-- there have been multiple cycles of plans and applies, but we only want to
-- operate on the most recent apply results.
--
-- To note: a plan that has no changes is considered a successful apply.  But it
-- only matters on merge.  So if the pull request is merged, we will include
-- plans.
    latest_applies_for_pull_request as (
        select distinct on (gpr.repository, gpr.pull_number, wmr.path, wmr.workspace)
            wmr.path,
            wmr.workspace,
            wmr.success,
            gwm.run_type,
            (plans.has_changes is null or plans.has_changes) as has_changes,
            gwm.created_at
        from gitlab_pull_requests as gpr
        inner join gitlab_work_manifests as gwm
            on gwm.repository = gpr.repository
               and gwm.pull_number = gpr.pull_number
        inner join work_manifest_results as wmr
            on wmr.work_manifest = gwm.id
        left join plans
            on plans.work_manifest = gwm.id
        where gpr.repository = \$1
              and gpr.pull_number = \$2
              and ((gpr.merged_at is null and gwm.run_type in ('autoapply', 'apply'))
                   or (gpr.merged_at is not null and gwm.run_type in ('autoapply', 'apply', 'autoplan', 'plan')))
        order by gpr.repository, gpr.pull_number, wmr.path, wmr.workspace, gwm.created_at desc
    ),
-- The output of this table is the repository and pull_number if ANY dirspace is
-- not considered complete.  This is really used as a "boolean", because we are
-- narrowing the query to our specific repository and pull request.  So if this
-- table has a row in it, it means we need to insert all of the rows for the
-- dirspaces it owns.  Otherwise if this table is empty, it deletes all rows.
-- This is how we get our "all or nothing" behaviour for locking dirspaces.
    locked as (
        select
            gpr.repository,
            gpr.pull_number
        from gitlab_pull_requests as gpr
        inner join all_dirspaces_for_pull_request as adspr
            on adspr.repository = gpr.repository
               and adspr.pull_number = gpr.pull_number
        left join latest_applies_for_pull_request as lapr
            on lapr.path = adspr.path
               and lapr.workspace = adspr.workspace
        left join gitlab_pull_request_latest_unlocks as unlocks
            on unlocks.repository = gpr.repository
               and unlocks.pull_number = gpr.pull_number
-- If the pull request IS NOT merged then it is locked for this dirspace if
-- there is an apply
        where (gpr.merged_at is null
               and lapr.path is not null
               and lapr.run_type in ('autoapply', 'apply')
               and (unlocks.unlocked_at is null or unlocks.unlocked_at < lapr.created_at))
-- If the pull request IS merged it is locked if there is no apply OR there is
-- an unsuccessful apply or there is a plan that has changes
              or (gpr.merged_at is not null
                  and (unlocks.unlocked_at is null or unlocks.unlocked_at < gpr.merged_at)
                  and adspr.lock_policy in ('strict', 'merge')
                  and not exists (select 1
                                  from pruned_dirspaces_for_pull_request as pdspr
                                  where pdspr.path = adspr.path
                                        and pdspr.workspace = adspr.workspace)
                  and (lapr.path is null
                       or not lapr.success
                       or (lapr.run_type in ('autoplan', 'plan') and lapr.has_changes)))
        group by gpr.repository, gpr.pull_number
    ),
    deleted as (
        delete from dirspace_pull_request_locks as dsprl
        using gitlab_pull_requests_map as gprm
        where gprm.core_id = dsprl.pull_request
              and gprm.repository_id = \$1
              and gprm.pull_number = \$2
              and not exists (select 1 from locked where repository = gprm.repository_id and pull_number = gprm.pull_number)
        returning dsprl.path, dsprl.workspace
    ),
    inserted as (
        insert into dirspace_pull_request_locks (path, workspace, pull_request, branch_target)
        select
            adspr.path,
            adspr.workspace,
            gprm.core_id as pull_request,
            adspr.branch_target
        from locked
        inner join all_dirspaces_for_pull_request as adspr
            on adspr.repository = locked.repository
               and adspr.pull_number = locked.pull_number
        inner join gitlab_pull_requests_map as gprm
            on gprm.repository_id = adspr.repository
               and gprm.pull_number = adspr.pull_number
        on conflict (path, workspace, pull_request) do nothing
        returning path, workspace
    )
    select
        path,
        workspace,
        op
    from (
        select i.path, i.workspace, 'inserted' as op from inserted as i
        union
        select d.path, d.workspace, 'deleted' as op from deleted as d
    )
    as t
$$;
