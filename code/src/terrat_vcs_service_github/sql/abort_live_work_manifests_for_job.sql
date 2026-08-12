-- A job that has reached a terminal state will never process another work
-- manifest event, so any work manifest of its own that is still live can never
-- be completed: the dispatcher will run it and then every poll from the runner
-- is answered with done, leaving it queued or running forever.  Abort them
-- along with the job.
update work_manifests
set state = 'aborted', completed_at = now()
from job_work_manifests as jwm
where jwm.work_manifest = work_manifests.id
      and jwm.job_id = $job
      and work_manifests.state in ('queued', 'running')
returning work_manifests.id
