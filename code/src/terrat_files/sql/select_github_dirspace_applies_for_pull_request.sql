with
latest_unlocks as (
    select
        repository,
        pull_number,
        max(unlocked_at) as unlocked_at
    from github_pull_request_unlocks
    group by repository, pull_number
),
work_manifests as (
    select
        gwm.id as id,
        gwm.repository as repository,
        gwm.pull_number as pull_number,
        gwm.base_sha as base_sha,
        gwm.sha as sha,
        gwm.run_type as run_type,
        gwm.completed_at as completed_at
    from github_work_manifests as gwm
    left join latest_unlocks as unlocks
        on unlocks.repository = gwm.repository and unlocks.pull_number = gwm.pull_number
    where gwm.run_kind = 'pr' and (unlocks.unlocked_at is null or unlocks.unlocked_at < gwm.created_at)
),
work_manifest_results as (
    select
        gwm.id as id,
        gwm.repository as repository,
        gwm.pull_number as pull_number,
        gwm.base_sha as base_sha,
        gwm.sha as sha,
        gwm.run_type as run_type,
        gwmr.path as path,
        gwmr.workspace as workspace,
        gwmr.success as success,
        row_number() over (partition by
                               gwm.repository,
                               gwmr.path,
                               gwmr.workspace
                           order by gwm.completed_at desc) as rn
    from work_manifests as gwm
    inner join github_work_manifest_results as gwmr
        on gwmr.work_manifest = gwm.id
),
applied_dirspaces as (
    select distinct
        gpr.repository as repository,
        gpr.pull_number as pull_number,
        results.path as path,
        results.workspace as workspace
    from github_pull_requests as gpr
    left join work_manifest_results as results
        on results.repository = gpr.repository and results.pull_number = gpr.pull_number
           and results.base_sha = gpr.base_sha
           and (results.sha = gpr.sha or results.sha = gpr.merged_sha)
    where results.rn = 1 and results.run_type in ('apply', 'autoapply', 'unsafe-apply') and results.success
)
select distinct
    applied.path,
    applied.workspace
from github_pull_requests as gpr
inner join github_installation_repositories as gir
    on gir.id = gpr.repository
inner join applied_dirspaces as applied
    on gpr.repository = applied.repository and gpr.pull_number = applied.pull_number
where gpr.repository = $repo_id and gpr.pull_number = $pull_number