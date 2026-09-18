with
dirspaces as (
    select path, workspace from unnest($dirs, $workspaces) as v(path, workspace)
),
latest_pull_request_merged_sha as (
    select
        merged_sha
    from github_pull_requests as gpr
    where merged_at is not null and repository = $repository
    order by merged_at desc
    limit 1
),
latest_dirspace_work_manifests as (
    select distinct on (gwm.repository, wmr.path, wmr.workspace)
        gwm.id,
        gwm.pull_number,
        wmr.path,
        wmr.workspace,
        wmr.success,
-- Whether this row is a run of this pull request at the refs the pull request
-- has now.  A run of this pull request at older refs is still a run of this
-- pull request, so it takes part in the ranking below and only this flag says
-- that its refs moved.  Holding such a row out of the ranking instead, which is
-- what this query did before, let any other pull request that ever touched the
-- dirspace outrank it, and a moved ref was then reported as that pull request
-- superseding the plan.
        (gpr.pull_number is not null
         and gpr.pull_number = $pull_number
         and gwm.base_sha = $base_ref
         and gwm.base_sha = gpr.base_sha
         and (
-- If the PR is not merged then we expect the branch ref to match the ref in the PR
              (gpr.merged_at is null
               and gpr.sha = $branch_ref
               and gwm.sha = gpr.sha)
-- If this pr is merged, then we expect the branch ref to match the latest pull request merged sha.
              or
              (gpr.merged_at is not null
               and (gwm.sha = lprms.merged_sha
                    or (gwm.sha = gpr.sha and gpr.merged_sha = lprms.merged_sha)))
         )) as refs_match
    from dirspaces as ds
    inner join work_manifest_results as wmr
        on wmr.path = ds.path and wmr.workspace = ds.workspace
    inner join github_work_manifests as gwm
        on wmr.work_manifest = gwm.id
    left join github_pull_requests as gpr
        on gpr.repository = gwm.repository and gpr.pull_number = gwm.pull_number
    left join latest_pull_request_merged_sha as lprms
        on true
    where gwm.repository = $repository
-- Consider work manifests that belong to this pull request, are some kind of
-- apply, or belong to a pull request that has been merged.
          and (gwm.pull_number is not distinct from $pull_number
               or gwm.run_type in ('autoapply', 'apply')
               or gpr.merged_at is not null)
-- A work manifest affects the base branch when it runs or, for a merged pull
-- request, when it is merged.  Rank by whichever happened later so that an
-- overlapping dirspace applied or merged by another pull request after this
-- plan was created supersedes it.
    order by gwm.repository, wmr.path, wmr.workspace,
             greatest(gwm.created_at, gpr.merged_at) desc, gwm.created_at desc
)
select
    ds.path,
    ds.workspace,
-- The four arms below are the four arms of the where clause, in the same order,
-- so the reason reported is the one that actually excluded the row.  The last
-- arm is a successful run of this pull request whose refs moved: a plan exists,
-- but not for the commit the pull request points at now.  That is the only arm
-- the intra-PR hash rule can clear, and the caller is what applies it.
    case
        when ldswm.id is null then 'never_planned'
        when ldswm.pull_number is distinct from $pull_number then 'invalidated'
        when not ldswm.success then 'last_run_failed'
        else 'never_planned'
    end,
    ldswm.pull_number
from dirspaces as ds
left join latest_dirspace_work_manifests as ldswm
    on ldswm.path = ds.path
       and ldswm.workspace = ds.workspace
left join plans
    on plans.work_manifest = ldswm.id
       and plans.path = ds.path
       and plans.workspace = ds.workspace
where ldswm.id is null
      or ldswm.pull_number is distinct from $pull_number
      or not ldswm.success
      or not ldswm.refs_match
