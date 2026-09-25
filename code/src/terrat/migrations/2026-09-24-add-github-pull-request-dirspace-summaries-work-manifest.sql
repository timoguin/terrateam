-- The run whose result decided the state of a dirspace, null when an evaluation
-- decided it from the runs of the pull request (RFD 2356).  A run on the head
-- that completed after the state decides the state of the dirspace instead,
-- except the run that decided the state: it completes after its result stores
-- the state.
alter table github_pull_request_dirspace_summaries
    add column if not exists work_manifest uuid
