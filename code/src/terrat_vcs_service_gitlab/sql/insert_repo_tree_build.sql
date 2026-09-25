insert into repo_tree_builds (sha, installation, built_by_script)
select
        $sha,
        gim.core_id,
        $built_by_script
from gitlab_installations_map as gim
where gim.installation_id = $installation_id
on conflict on constraint repo_tree_builds_pkey
-- A tree the script made stays the tree of that commit: a later read of the forge
-- overwrites no producer, because only a script tree answers an evaluation whose
-- tree builder is on.
do update set built_by_script = coalesce(repo_tree_builds.built_by_script, false)
                                or coalesce(excluded.built_by_script, false)
