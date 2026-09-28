-- One member of a tenant, with the raw capabilities object so the caller can classify how that
-- user's grants cover this tenant (see select_tenant_users.sql for why the coverage is not derived
-- in SQL).
select
    u.id,
    u.name,
    u.email,
    u.type,
    u.avatar_url,
    u.capability_trie,
    to_char(tu.created_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')
from tenant_users as tu
inner join users as u
    on u.id = tu.user_id
where tu.tenant_id = $tenant_id and u.id = $user_id and u.state = 'active'
