create index concurrently if not exists work_manifests_pending_idx
       on work_manifests (repo, run_kind, created_at)
       where state in ('queued', 'running');
