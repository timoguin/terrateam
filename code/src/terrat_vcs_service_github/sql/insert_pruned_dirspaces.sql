insert into pruned_dirspaces (path, pull_request, workspace)
select
    x.path,
    prm.core_id,
    x.workspace
from unnest($path, $workspace) as x(path, workspace)
inner join github_pull_requests_map as prm
    on prm.repository_id = $repo_id and prm.pull_number = $pull_number
on conflict (path, workspace, pull_request) do nothing
