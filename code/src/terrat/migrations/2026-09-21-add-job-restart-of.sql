-- The job that a drift reconcile restarts.  When the files of a drift change
-- while its reconcile runs, the server stores the result and reconciles again
-- with a new job at the new head (RFD 2356).  The chain of these jobs is what
-- limits how many times that happens.  Nullable: every other job has none, and
-- a server that does not know the column never writes it.
alter table jobs add column if not exists restart_of uuid
