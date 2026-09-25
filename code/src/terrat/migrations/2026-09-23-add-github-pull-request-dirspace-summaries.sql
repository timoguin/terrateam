-- The state of each dirspace of a pull request at one of its commits, as the
-- intra-PR hash rules decide it (RFD 2356).  A run on an older commit can still
-- count for the head: a push that changes no file of a dirspace keeps its plan
-- and its apply, and a stale run can become good again (retroactive freshness).
-- The unified summary comment reads these rows, because it cannot apply the
-- rules itself.
--
-- sha: the head of the pull request that the state is for.
-- state: applied, planned, failed or stale.
-- updated_at: when the state was decided.  A run on the same commit that is
--   newer than the state decides the state of the dirspace instead.
create table if not exists github_pull_request_dirspace_summaries (
    repository bigint not null,
    pull_number bigint not null,
    sha text not null,
    path text not null,
    workspace text not null,
    state text not null,
    updated_at timestamptz not null default current_timestamp,
    foreign key (repository, pull_number) references github_pull_requests (repository, pull_number),
    primary key (repository, pull_number, sha, path, workspace),
    constraint github_pull_request_dirspace_summaries_state_check
        check (state in ('applied', 'planned', 'failed', 'stale'))
)
