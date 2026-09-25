-- The heads that a run operated against (RFD 2356).  The runner of a pull request
-- merges the head of the destination branch when the operation starts, thus the
-- destination head at the start is a commit of the run too.  At the result the
-- server reads the heads again.  A run is stale when the files of its dirspaces
-- changed between the heads at the start and the heads at the result, and a
-- later evaluation of the pull request compares the same pairs of commits.
--
-- start_dest_sha: the head of the destination branch when the runner took the
--   work manifest of an open pull request.
-- result_sha: the head of the branch of the run (as start_sha) when the result
--   arrived.
-- result_dest_sha: the head of the destination branch when the result of an
--   open pull request arrived.
--
-- Nullable: a work manifest that ran before these columns existed has none, and a
-- server that does not know the columns never writes them.
alter table work_manifests
    add column if not exists start_dest_sha text,
    add column if not exists result_sha text,
    add column if not exists result_dest_sha text;
