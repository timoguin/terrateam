-- Create a tenant, refusing a name another tenant already holds.
--
-- The guard lives in the statement for the same reason it does in update_tenant_name.sql:
-- tenants.name carries no unique index -- adding one needs some work,
-- https://github.com/stategraph/mono/issues/2109 -- so zero returned rows is how the caller learns
-- the name was taken. Same residual race as the rename guard: without the unique index two
-- concurrent inserts of one name can both pass the not-exists check. Closing that needs the index,
-- not a bigger statement.
insert into tenants (name)
select $name
where not exists (select 1 from tenants as o where o.name = $name)
returning id
