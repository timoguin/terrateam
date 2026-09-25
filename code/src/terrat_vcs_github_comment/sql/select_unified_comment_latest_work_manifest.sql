-- The newest work manifest of a pull request that tracks a unified comment.
-- The refresh of the comment is keyed by a work manifest, and an evaluation of
-- a pull request event can change the states of its dirspaces without one.
select gwm.id
from github_work_manifests as gwm
inner join github_unified_comments as guc
    on guc.repository = gwm.repository and guc.pull_number = gwm.pull_number
where gwm.repository = $repository and gwm.pull_number = $pull_number
order by gwm.created_at desc
limit 1
