insert into github_unified_comments (repository, pull_number, dirty, output_details)
select
    gwm.repository,
    gwm.pull_number,
    1,
    $output_details
from github_work_manifests as gwm
where gwm.id = $work_manifest and gwm.pull_number is not null
on conflict (repository, pull_number)
do update set dirty = github_unified_comments.dirty + 1,
              output_details = excluded.output_details
