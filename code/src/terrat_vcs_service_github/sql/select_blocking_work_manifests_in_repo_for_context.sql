-- The work manifests that hold back an apply queued against these dirspaces.
-- This mirrors the [blocked_dirspaces] rule of select_next_work_manifest.sql:
-- an apply waits for every operation *running* against its dirspaces.  A queued
-- work manifest is not a blocker, it waits on the same running work.
--
-- Unlike select_conflicting_work_manifests_in_repo_for_context.sql this does not
-- stop the apply.  The apply is queued and legitimately waits; the rows here are
-- what it waits for, so the user can be told instead of being left with the
-- rocket reaction and nothing else.
with
context as (
  select
    jc.id,
    grm.repository_id as repo
  from job_contexts as jc
  inner join github_repositories_map as grm
    on grm.core_id = jc.repo
  where jc.id = $context_id
),
dirspaces as (
    select dir, workspace from unnest($dirs, $workspaces) as v(dir, workspace)
)
select
    gwm.id
from github_work_manifests as gwm
inner join context as c
  on c.repo = gwm.repository
left join github_pull_request_latest_unlocks as latest_unlocks
    on latest_unlocks.repository = gwm.repository and latest_unlocks.pull_number = gwm.pull_number
left join github_drift_latest_unlocks as latest_drift_unlocks
    on latest_drift_unlocks.repository = gwm.repository
where gwm.state = 'running'
-- The unlock rules the dispatcher applies, so this reports exactly what the
-- dispatcher waits for.  An unlocked work manifest holds nothing back.
      and ((gwm.run_kind = 'pr'
            and (latest_unlocks.unlocked_at is null
                 or latest_unlocks.unlocked_at < gwm.created_at))
           or (gwm.run_kind = 'drift'
               and (latest_drift_unlocks.unlocked_at is null
                    or latest_drift_unlocks.unlocked_at < gwm.created_at))
           or gwm.run_kind = 'index')
-- Our own work is not something we wait for.
      and not exists (select 1
                      from job_work_manifests as jwm
                      where jwm.work_manifest = gwm.id and jwm.job_id = $job_id)
      and exists (select 1
                  from work_manifest_dirspaceflows as gwmdsfs
                  inner join dirspaces
                    on dirspaces.dir = gwmdsfs.path
                       and dirspaces.workspace = gwmdsfs.workspace
                  where gwmdsfs.work_manifest = gwm.id)
order by gwm.created_at
