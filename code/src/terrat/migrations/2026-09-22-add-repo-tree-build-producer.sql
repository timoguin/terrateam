-- Who made the stored tree of a commit: the tree builder script, or a plain read
-- of the forge.  The ids of the two are not comparable, and only a script tree
-- answers an evaluation whose tree builder is on.  Nullable: a row written
-- before this column says nothing about its producer.
alter table repo_tree_builds add column if not exists built_by_script boolean;
