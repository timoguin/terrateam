select
    rm.core_id,
    prm.core_id
from gitlab_repositories_map as rm
inner join gitlab_pull_requests_map as prm
    on prm.repository_id = rm.repository_id
where rm.repository_id = $repo_id and prm.pull_number = $pull_number
