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
-- A work manifest that belongs to a compute node which already runs must not
-- start a second action run.  The node picks it up on its next poll instead.
--
-- The filter belongs here, and not in the final select, because this is where
-- row_number() ranks a repository's queued work manifests and the final select
-- takes rn = 1.  Such a work manifest is still 'queued', so it can rank first.
-- A filter in the final select would then return no row at all, and the
-- dispatcher would stop dispatching for that repository until the running node
-- finished.
--
-- A work manifest with no compute node is one made before the phase that makes
-- a node with each work manifest.  It keeps the old path.
--
-- Neither join can multiply rows: compute_node_work has a unique index on
-- work_manifest, and compute_nodes joins on its primary key.  Every work
-- manifest therefore still contributes one row, and the ranking of the others
-- does not move.
--
-- $work_manifest_id gives the query a second mode.  When it is null the query
-- answers the dispatcher: which work manifest starts the next action run.  When
-- it is set the query answers the poll of a compute node: may this one work
-- manifest run now.  The two modes share every rule above, which is the point.
-- A rule written twice would drift, and the rules here decide whether two
-- applies can touch one dirspace at the same time.
--
-- The second mode drops two conditions of the first, and only those two.  It
-- does not rank, because it asks about one work manifest and not about the next
-- one of a repository.  It does not ask the state of the compute node, because
-- the node that asks is running by definition.
next_work_manifests as (
    select
        wms.id,
        cn.id as compute_node,
        row_number() over (partition by wms.repository order by wms.priority, wms.created_at) as rn
    from wms
    left join rejected_work_manifests as rwm on rwm.id = wms.id
    left join compute_node_work as cnw on cnw.work_manifest = wms.id
    left join compute_nodes as cn on cn.id = cnw.compute_node
    where wms.state = 'queued'
          and rwm.id is null
          and ($work_manifest_id is not null
               or cn.id is null
               or cn.state = 'queued')
          and ($work_manifest_id is null or wms.id = $work_manifest_id)
)
select wm.id, nwm.compute_node from work_manifests as wm
inner join next_work_manifests as nwm on nwm.id = wm.id
left join flow_states
  on flow_states.id = wm.id
where ($work_manifest_id is not null or nwm.rn = 1) and wm.state = 'queued' and ((flow_states.id is null and $new_age) or (flow_states.id is not null and not $new_age))
for update of wm skip locked
limit 1
