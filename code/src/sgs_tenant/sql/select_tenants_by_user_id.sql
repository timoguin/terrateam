select id, name from tenants
inner join tenant_users
    on tenant_users.tenant_id = tenants.id
where tenant_users.user_id = $user_id
