-- A page of a tenant's active members, oldest membership first.
--
-- The raw capabilities object is returned rather than a derived boolean.  How an allow-list covers a
-- tenant is a three-way answer -- not covered, covered by naming it exactly, or covered by something
-- wider (an absent list, a glob) -- and the one implementation of those semantics lives in
-- Sg_caps_match.  Deriving it here would be a second copy of the glob-and-negation rules, and a
-- second copy of an authorization rule is a rule that drifts.  The projection is per-row and
-- unfiltered, so nothing is pulled into OCaml that SQL should have discarded.
--
-- $cursor and $cursor_id are the created_at and user id of the last row of the previous page.  Both
-- are needed: members added together share a created_at (it defaults to now() per insert), so a
-- created_at-only cursor would skip or repeat whichever of them straddles a page boundary.  The pair
-- matches the (created_at, id) sort exactly.
select
    u.id,
    u.name,
    u.email,
    u.type,
    u.avatar_url,
    u.capability_trie,
    to_char(tu.created_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
    -- Stable across pages: the tenant's whole active-member count, computed without the cursor
    -- predicate.  Mirrors the main query's non-cursor filters (this tenant, active users).
    (select count(*)
     from tenant_users as c_tu
     inner join users as c_u on c_u.id = c_tu.user_id
     where c_tu.tenant_id = $tenant_id and c_u.state = 'active') as total_count
from tenant_users as tu
inner join users as u
    on u.id = tu.user_id
where tu.tenant_id = $tenant_id
  and u.state = 'active'
  and ($cursor::timestamptz is null
       or (tu.created_at, u.id) > ($cursor::timestamptz, $cursor_id::uuid))
order by tu.created_at asc, u.id asc
limit $limit
