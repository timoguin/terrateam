select
    wso.step,
    wso.payload->'outputs'
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
order by wm.created_at desc, wso.idx desc
limit 1
