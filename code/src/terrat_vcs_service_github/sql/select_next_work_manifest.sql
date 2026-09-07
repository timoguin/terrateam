with
wms as (
    select
        wm.id as id,
        wm.created_at as created_at,
        grm.repository_id as repository,
        wm.state as state,
        (case wm.run_type
         when 'autoapply' then 'apply'
         when 'apply' then 'apply'
         when 'unsafe-apply' then 'apply'
         when 'autoplan' then 'plan'
         when 'plan' then 'plan'
         end) as unified_run_type,
        (case wm.run_type
         when 'autoapply' then 0
         when 'apply' then 0
         when 'unsafe-apply' then 0
         when 'autoplan' then 1
         when 'plan' then 1
         end) as priority
    from work_manifests as wm
    inner join github_repositories_map as grm
        on grm.core_id = wm.repo
    inner join github_installation_repositories as gir
        on gir.id = grm.repository_id
    left join lateral (
        select pru.unlocked_at
        from pull_request_unlocks as pru
        where pru.pull_request = wm.pull_request
        order by pru.unlocked_at desc
        limit 1
    ) as unlocks on true
    left join lateral (
        select du.unlocked_at
        from drift_unlocks as du
        where du.repo = (select core_id
                         from github_repositories_map
                         where repository_id = grm.repository_id)
        order by du.unlocked_at desc
        limit 1
    ) as drift_unlocks on true
    where wm.state in ('queued', 'running')
          and ((wm.run_kind = 'pr'
                and (unlocks.unlocked_at is null or unlocks.unlocked_at < wm.created_at))
               or (wm.run_kind = 'drift'
                   and (drift_unlocks.unlocked_at is null or drift_unlocks.unlocked_at < wm.created_at))
               or wm.run_kind = 'index')
),
dirspaces_for_work_manifests as (
    select
        work_manifest,
        path,
        workspace
    from work_manifest_dirspaceflows as gwmds
    inner join wms
        on gwmds.work_manifest = wms.id
),
queued_dirspaces_per_repo as (
    select distinct
        wms.repository as repository,
        wms.unified_run_type as unified_run_type,
        path,
        workspace
    from work_manifest_dirspaceflows as gwmds
    inner join wms
        on gwmds.work_manifest = wms.id
    where wms.state = 'queued'
),
running_dirspaces_per_repo as (
    select distinct
        wms.repository as repository,
        wms.unified_run_type as unified_run_type,
        path,
        workspace
    from work_manifest_dirspaceflows as gwmds
    inner join wms
        on gwmds.work_manifest = wms.id
    where wms.state = 'running'
),
-- The dirspaces a queued work manifest cannot be run against yet, along with
-- the kind of work manifest that has to wait on it.  A plan and an apply never
-- run against the same dirspace at the same time, and two applies never run
-- against the same dirspace at the same time.
blocked_dirspaces as (
    -- An apply waits for every operation running against its dirspaces to
    -- complete.  It does not cancel them.
    select distinct
        rds.repository as repository,
        rds.path as path,
        rds.workspace as workspace,
        'apply' as unified_run_type
    from running_dirspaces_per_repo as rds
    union
    -- A plan waits for an apply running against its dirspaces.
    select distinct
        rds.repository as repository,
        rds.path as path,
        rds.workspace as workspace,
        'plan' as unified_run_type
    from running_dirspaces_per_repo as rds
    where rds.unified_run_type = 'apply'
    union
    -- A queued apply skips the line: every plan queued against its dirspaces,
    -- those queued before it and those queued after it, runs only once the
    -- apply has completed.  This is what bounds how long an apply waits, the
    -- set of work it is waiting on can only shrink.
    select distinct
        qds.repository as repository,
        qds.path as path,
        qds.workspace as workspace,
        'plan' as unified_run_type
    from queued_dirspaces_per_repo as qds
    where qds.unified_run_type = 'apply'
),
-- Reject all those work manifests that have a dirspace blocked for their kind
-- of run
rejected_work_manifests as (
    select distinct wms.id as id from wms
    inner join dirspaces_for_work_manifests as dswm
        on dswm.work_manifest = wms.id
    inner join blocked_dirspaces as bds
        on bds.repository = wms.repository
           and bds.path = dswm.path
           and bds.workspace = dswm.workspace
           and bds.unified_run_type = wms.unified_run_type
),
next_work_manifests as (
    select
        wms.id,
        row_number() over (partition by wms.repository order by wms.priority, wms.created_at) as rn
    from wms
    left join rejected_work_manifests as rwm on rwm.id = wms.id
    where wms.state = 'queued' and rwm.id is null
)
select wm.id from work_manifests as wm
inner join next_work_manifests as nwm on nwm.id = wm.id
left join flow_states
  on flow_states.id = wm.id
where nwm.rn = 1 and wm.state = 'queued' and ((flow_states.id is null and $new_age) or (flow_states.id is not null and not $new_age))
for update of wm skip locked
limit 1
