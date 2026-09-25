-- Whether newer plans of the same context cover each dirspace of the given work manifest
-- (RFD 2356).
--
-- A newer plan is a plan work manifest that is not aborted, of a plan job made after the given
-- job.  When each dirspace has a newer plan, the result of that newer plan is the most recent plan
-- of the dirspace, thus the given plan is never used.  A newer job that has no work manifest yet
-- covers nothing: abort_duplicate_work_manifests_for_context.sql aborts the older plan when that
-- job makes its work manifests.
with
cur as (
  select context_id, created_at from jobs where id = $job_id
),
newer_dirspaces as (
  select theirs.path, theirs.workspace
  from jobs as newer
  inner join cur
    on cur.context_id = newer.context_id
  inner join job_work_manifests as jwm
    on jwm.job_id = newer.id
  inner join work_manifests as wm
    on wm.id = jwm.work_manifest
  inner join work_manifest_dirspaceflows as theirs
    on theirs.work_manifest = wm.id
  where newer.created_at > cur.created_at
        and newer.params->>'type' = 'plan'
        and newer.params->>'kind' is null
        and wm.run_type in ('autoplan', 'plan')
        and wm.state <> 'aborted'
),
mine as (
  select path, workspace
  from work_manifest_dirspaceflows
  where work_manifest = $work_manifest_id
)
select 1
where exists (select 1 from mine)
      and not exists (
        select 1
        from mine
        where not exists (
          select 1
          from newer_dirspaces as n
          where n.path = mine.path and n.workspace = mine.workspace))
