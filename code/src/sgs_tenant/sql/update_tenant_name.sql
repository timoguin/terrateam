-- Rename a tenant, refusing a name another tenant already holds.
--
-- tenants.name carries no unique index -- adding one needs a de-duplication pass first, see the
-- 2026-07-30-add-tenant-administration.sql notes -- so the guard lives in the statement.  The caller
-- locks and confirms the row first (select_tenant_for_update.sql), which is what makes zero returned
-- rows unambiguous: the tenant exists, so the name must have been taken.
update tenants
set name = $name
where id = $tenant_id
  and not exists (select 1 from tenants as o where o.name = $name and o.id <> $tenant_id)
returning id, name
