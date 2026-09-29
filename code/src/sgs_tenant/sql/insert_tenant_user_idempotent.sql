-- Add a member, tolerating one that already exists.
--
-- A separate statement from insert_tenant_user.sql rather than a loosening of it: the OAuth callback
-- and users/create rely on a duplicate being a genuine error, and silently swallowing it there would
-- hide a bug.  This variant exists for the invitation-accept path, which must be safe to retry.
insert into tenant_users (tenant_id, user_id)
values ($tenant_id, $user_id)
on conflict (tenant_id, user_id) do nothing
