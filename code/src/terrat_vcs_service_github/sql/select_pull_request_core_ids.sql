select
    rm.core_id,
    prm.core_id
from github_repositories_map as rm
inner join github_pull_requests_map as prm
    on prm.repository_id = rm.repository_id
where rm.repository_id = $repo_id and prm.pull_number = $pull_number
