-- The most recent run of each named dirspace of the context, once for a plan and once for an
-- apply, with the sha of the run and the time of its work manifest.
--
-- Unlike select_dirspace_applies_for_context.sql, this does not test the sha of the work manifest
-- against the sha of the branch.  Whether a run still counts is a question about the hashes of
-- the files of that dirspace, and the caller answers it, thus this query gives the sha of the run
-- and lets the caller decide.  The time is what puts the runs of the layers in order.
with
context as (
  select
    jc.id,
    grm.repository_id as repo,
    gprm.pull_number as pull_number
  from job_contexts as jc
  inner join gitlab_repositories_map as grm
    on grm.core_id = jc.repo
  left join gitlab_pull_requests_map as gprm
    on gprm.core_id = (jc.params->>'pull_request')::uuid
  where jc.id = $context_id
),
jobs as (
  select jobs.*
  from jobs
  inner join context as jc
    on jc.id = jobs.context_id
),
wm as (
  select
      wm.id as id,
      wm.sha as sha,
      wm.created_at as created_at,
      (case
         when wm.run_type in ('autoapply', 'apply', 'unsafe-apply') then 'apply'
         when wm.run_type in ('autoplan', 'plan') then 'plan'
         else wm.run_type
       end) as run_type
  from gitlab_work_manifests as wm
  inner join context as c
    on c.repo = wm.repository
  inner join job_work_manifests as jwm
    on jwm.work_manifest = wm.id
  inner join jobs
    on jwm.job_id = jobs.id
  left join gitlab_pull_request_latest_unlocks as unlocks
    on unlocks.repository = wm.repository and unlocks.pull_number = wm.pull_number
  left join gitlab_drift_latest_unlocks as drift_unlocks
    on drift_unlocks.repository = wm.repository
  where (c.pull_number is not distinct from wm.pull_number)
        and ((jobs.params->'kind' is null
              and (unlocks.unlocked_at is null or unlocks.unlocked_at < wm.created_at))
             or (jobs.params->'kind'->>'type' = 'drift'
                 and (drift_unlocks.unlocked_at is null or drift_unlocks.unlocked_at < wm.created_at)))
),
dirspaces as (
    select path, workspace from unnest($dirs, $workspaces) as v(path, workspace)
),
-- A plan which found no changes has nothing to apply, thus the caller needs to know whether the
-- plan found changes.  A run with no plan row counts as a run with changes, which keeps the
-- dirspace unapplied.
runs as (
  select
      wmr.path as path,
      wmr.workspace as workspace,
      wm.run_type as run_type,
      wm.sha as sha,
      wm.created_at as created_at,
      coalesce(plans.has_changes, true) as has_changes,
      row_number() over (partition by wmr.path, wmr.workspace, wm.run_type
                         order by wm.created_at desc) as rn
  from wm
  inner join work_manifest_results as wmr
    on wmr.work_manifest = wm.id
  inner join dirspaces as ds
    on ds.path = wmr.path and ds.workspace = wmr.workspace
  left join plans
    on plans.work_manifest = wm.id and plans.path = wmr.path and plans.workspace = wmr.workspace
  where wmr.success
)
select
  ds.path,
  ds.workspace,
  last_plan.sha,
  to_char(last_plan.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
  last_plan.has_changes,
  last_apply.sha,
  to_char(last_apply.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
from dirspaces as ds
left join runs as last_plan
  on last_plan.path = ds.path
     and last_plan.workspace = ds.workspace
     and last_plan.run_type = 'plan'
     and last_plan.rn = 1
left join runs as last_apply
  on last_apply.path = ds.path
     and last_apply.workspace = ds.workspace
     and last_apply.run_type = 'apply'
     and last_apply.rn = 1
