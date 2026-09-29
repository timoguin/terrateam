-- The capabilities of $tenant_id's active members.
select u.capability_trie
from tenant_users as tu
inner join users as u
    on u.id = tu.user_id
where tu.tenant_id = $tenant_id
  and u.state = 'active'
