-- Lock a tenant row for a rename, so the existence check and the name-collision check below it
-- cannot race another rename.
select id, name from tenants where id = $tenant_id for update
