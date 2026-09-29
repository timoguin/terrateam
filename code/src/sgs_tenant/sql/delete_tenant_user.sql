-- Drop a membership row.  Idempotent: removing a non-member affects nothing and is not an error.
--
-- This revokes visibility only.  Sgs_tenant.enforce_user (and therefore every tenant-scoped
-- endpoint) consults this table on each request, so access ends immediately -- but the user's
-- capabilities may still name the tenant, which every user-facing API reads as their role and which
-- can still be minted into an access token.  The caller must pair this with
-- Sgs_user.revoke_tenant in the same transaction.
delete from tenant_users where tenant_id = $tenant_id and user_id = $user_id
