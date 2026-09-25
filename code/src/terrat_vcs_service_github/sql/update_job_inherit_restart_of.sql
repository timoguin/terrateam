-- The job $id continues the job $from_job_id, thus it is in the same chain of restarts
-- (RFD 2356).
update jobs
set restart_of = (select from_job.restart_of from jobs as from_job where from_job.id = $from_job_id)
where id = $id
