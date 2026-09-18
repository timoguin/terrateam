-- The paths whose contents are not the same in two trees of one repository.
--
-- A path which only one of the two trees holds is a change as well, thus the join is a full outer
-- join.  A row with no id says nothing about the contents of that file, thus it counts as a
-- change: a tree which is not there must mean "run it" and never "skip it".
--
-- The join reads the rows of the two trees through the (installation, sha, path) index, and it
-- gives back the paths which changed and no others.  Thus what crosses to the caller, and what the
-- change match then walks, follows the number of paths which changed.  The work in the database
-- does not: both trees are read whole, thus the cost here follows the number of files in the
-- repository.  The caller keeps the answer of each sha for the evaluation, and it asks
-- repo_tree_builds first, so that a sha with no tree costs a lookup of a primary key rather than
-- this join over a tree which is not there.
with
base_tree as (
    select path, id
    from github_repo_trees
    where installation_id = $installation_id and sha = $base_sha
),
head_tree as (
    select path, id
    from github_repo_trees
    where installation_id = $installation_id and sha = $sha
)
select coalesce(head_tree.path, base_tree.path)
from head_tree
full outer join base_tree
     on head_tree.path = base_tree.path
where head_tree.path is null
      or base_tree.path is null
      or head_tree.id is null
      or base_tree.id is null
      or head_tree.id is distinct from base_tree.id
