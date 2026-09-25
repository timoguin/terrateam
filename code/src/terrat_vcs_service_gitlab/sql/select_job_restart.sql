-- The job that restarts the given job, if any (RFD 2356).  A restart is always a plan job.  The
-- reconcile apply job of a restart carries the same link, and it is not the restart.
select id from jobs where restart_of = $id and params->>'type' = 'plan' order by created_at desc limit 1
