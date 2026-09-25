-- Built concurrently, so that the build does not block writes to jobs.
create index concurrently if not exists jobs_restart_of_idx on jobs (restart_of)
