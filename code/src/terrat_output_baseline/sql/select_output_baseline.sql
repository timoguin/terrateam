with
--- The most recent successful apply of the dirspace in the pull request under evaluation.  The
--- baseline is older than it, so an apply in another pull request after it does not move the
--- baseline.
current_apply as (
    select
        max(wm.created_at) as created_at
    from work_manifests as wm
    inner join work_manifest_results as wmr
        on wmr.work_manifest = wm.id
    inner join workflow_step_outputs as wso
        on wso.work_manifest = wm.id
    where wm.repo = $repo
          and wm.pull_request = $pull_request
          and wmr.path = $dir
          and wmr.workspace = $workspace
          and wmr.success
          and wso.scope->>'type' = 'dirspace'
          and wso.scope->>'dir' = $dir
          and wso.scope->>'workspace' = $workspace
          and wso.step in ('tf/apply', 'custom/apply', 'pulumi/apply', 'stategraph/apply', 'fly/apply')
          and wso.success
)
select
    wso.step,
    wso.payload->'outputs'
from work_manifests as wm
inner join work_manifest_results as wmr
    on wmr.work_manifest = wm.id
inner join workflow_step_outputs as wso
    on wso.work_manifest = wm.id
cross join current_apply
where wm.repo = $repo
      and wm.pull_request <> $pull_request
      and (current_apply.created_at is null or wm.created_at < current_apply.created_at)
      and wmr.path = $dir
      and wmr.workspace = $workspace
      and wmr.success
      and wso.scope->>'type' = 'dirspace'
      and wso.scope->>'dir' = $dir
      and wso.scope->>'workspace' = $workspace
      and wso.step in ('tf/apply', 'custom/apply', 'pulumi/apply', 'stategraph/apply', 'fly/apply')
      and wso.success
order by wm.created_at desc, wso.idx desc
limit 1
