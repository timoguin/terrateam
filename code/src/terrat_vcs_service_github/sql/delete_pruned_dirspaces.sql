delete from pruned_dirspaces as pd
using github_pull_requests_map as prm
where prm.core_id = pd.pull_request
      and prm.repository_id = $repo_id
      and prm.pull_number = $pull_number
