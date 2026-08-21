-- [select_repo_tree.sql] resolves a base sha to the pull requests carrying it as
-- their head or merge sha.  Neither column was indexed, so the lookup
-- sequentially scanned the whole pull request table on every evaluation.
--
-- Two single column indexes rather than one composite: the query ORs the two
-- columns, and the planner can combine them with a BitmapOr only when each has
-- an index of its own.
create index concurrently if not exists github_pull_requests_sha_idx
       on github_pull_requests (sha);

create index concurrently if not exists github_pull_requests_merged_sha_idx
       on github_pull_requests (merged_sha);

create index concurrently if not exists gitlab_pull_requests_sha_idx
       on gitlab_pull_requests (sha);

create index concurrently if not exists gitlab_pull_requests_merged_sha_idx
       on gitlab_pull_requests (merged_sha);
