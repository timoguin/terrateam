select
  dwm.branch,
  coalesce(gds.reconcile, false)
from drift_work_manifests as dwm
inner join gitlab_work_manifests as gwm
  on gwm.id = dwm.work_manifest
left join gitlab_drift_schedules as gds
  on gds.repository = gwm.repository
where dwm.work_manifest = $work_manifest
