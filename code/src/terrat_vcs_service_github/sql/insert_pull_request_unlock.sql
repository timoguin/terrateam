-- Only insert an unlock if the pull request exists.  The runs before an unlock
-- do not count, thus the stored state of each dirspace becomes stale: the
-- summary comment still shows the plan of those runs, and the dirspace must be
-- planned again (RFD 2356).  Mark the comment dirty, thus the next drain shows
-- it.
with
pull_request as (
    select core_id, repository_id, pull_number
    from github_pull_requests_map
    where repository_id = $repository and pull_number = $pull_number
),
unlock as (
    insert into pull_request_unlocks (pull_request)
    select core_id from pull_request
),
stale as (
    update github_pull_request_dirspace_summaries as s
    set state = 'stale', updated_at = current_timestamp
    from pull_request as pr
    where s.repository = pr.repository_id and s.pull_number = pr.pull_number
    returning 1
)
update github_unified_comments as guc
set dirty = guc.dirty + 1
from pull_request as pr
where guc.repository = pr.repository_id
  and guc.pull_number = pr.pull_number
  and exists (select 1 from stale)
