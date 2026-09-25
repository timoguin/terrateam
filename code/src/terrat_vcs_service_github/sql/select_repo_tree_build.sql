select rtb.sha
from repo_tree_builds as rtb
inner join github_installations_map as gim
      on gim.core_id = rtb.installation
where gim.installation_id = $installation_id
      and rtb.sha = $sha
      -- With $script_only, only a tree the tree builder script made answers.
      and (not $script_only or coalesce(rtb.built_by_script, false))
