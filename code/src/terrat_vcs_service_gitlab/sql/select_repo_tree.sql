with
rt1 as (
    select * from gitlab_repo_trees where installation_id = $installation_id and sha = $sha
),
base_shas as (
    -- The shas the base tree may be stored under.  A pull request carries its
    -- head sha and, once merged, its merge sha, and the tree may have been
    -- built under either.
    --
    -- Collecting them into a set first is what lets the lookup below use the
    -- (installation, sha, path) index.  Expressed as a join condition,
    -- "rt.sha in (bsp.sha, bsp.merged_sha)" is an OR, which cannot become an
    -- index condition: the planner fell back to reading every tree row the
    -- installation had ever stored and discarding almost all of them, so the
    -- cost grew with every sha ever built rather than with the size of one
    -- tree.
    select bsp.sha as sha
    from gitlab_pull_requests as bsp
    where bsp.sha = $base_sha or bsp.merged_sha = $base_sha
    union
    select bsp.merged_sha as sha
    from gitlab_pull_requests as bsp
    where (bsp.sha = $base_sha or bsp.merged_sha = $base_sha) and bsp.merged_sha is not null
),
rt2 as (
    -- One row per path.  More than one of the shas above can have a stored
    -- tree, and then the left join below multiplies rt1 and the caller sees the
    -- same path more than once, with conflicting answers.  Prefer the tree of
    -- the base sha itself; it is the direct answer, and the pull request lookup
    -- above is only a fallback for when the tree was built under the other sha.
    --
    -- "= any (array(...))" rather than "in (...)": with a subquery the planner
    -- hash joins against a full scan of the tree table, but an array is a value
    -- it can probe with, so the sha becomes part of the index condition
    -- alongside the installation.
    select distinct on (rt.path) rt.path, rt.id
    from gitlab_repo_trees as rt
    where rt.installation_id = $installation_id
      and rt.sha = any (array(select sha from base_shas))
    order by rt.path, (rt.sha is not distinct from $base_sha) desc, rt.sha
)
select
    rt1.path,
    (case
       when rt1.changed is not null then rt1.changed
       when rt1.id is not null and rt2.id is not null then rt1.id <> rt2.id
       when rt1.id is not null and rt2.id is null then true
       else null
    end)
from rt1
left join rt2
     on rt1.path = rt2.path
