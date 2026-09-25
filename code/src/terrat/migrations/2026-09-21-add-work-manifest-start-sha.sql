-- The head of the branch at the moment the runner took the work manifest.  A
-- merge can move the destination branch while the run operates, and the result
-- is compared with this commit to decide whether the run is stale (RFD 2356).
-- Nullable: a work manifest that started before this column existed has none,
-- and a server that does not know the column never writes it.
alter table work_manifests add column if not exists start_sha text;
