-- Whether the unified comment renders its inline output details section, snapshotted from
-- notifications.summary.output_details.enabled by the result that marked the comment dirty.
alter table github_unified_comments
    add column if not exists output_details boolean not null default false;
