-- The pull request a work manifest belongs to, for callers that need it before
-- the unified comment tracking row exists.  Drift work manifests have a null
-- pull number and match no rows.
select gwm.repository, gwm.pull_number
from github_work_manifests as gwm
where gwm.id = $work_manifest and gwm.pull_number is not null
