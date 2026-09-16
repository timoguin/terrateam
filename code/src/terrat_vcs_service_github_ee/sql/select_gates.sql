-- A gate whose dir and workspace are both empty applies to the whole pull
-- request and blocks every dirspace.  Any other gate blocks only the dirspaces
-- named in $dirs and $workspaces.
with
dirspaces as (
    select dir, workspace from unnest($dirs, $workspaces) as v(dir, workspace)
)
select
  gg.name,
  gg.token,
  gg.gate,
  gg.dir,
  gg.workspace
from github_gates as gg
inner join github_pull_requests as gpr
  on (gpr.repository = gg.repository and gpr.pull_number = gg.pull_number
      and (gpr.sha = gg.sha or gpr.merged_sha = gg.sha))
left join dirspaces as ds
  on ds.dir = gg.dir and ds.workspace = gg.workspace
where gg.repository = $repository and gg.pull_number = $pull_number
      and (ds.dir is not null or (gg.dir = '' and gg.workspace = ''))
