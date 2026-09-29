-- Revoke every browser login session the user holds.  A login session is a snapshot of the
-- capabilities at sign-in, so once the capabilities change the snapshot is stale in either
-- direction: a revoked grant must stop authorizing, and a new grant is not in it.  Deleting the
-- rows forces a fresh sign-in, which snapshots the current capabilities.  'api' tokens are
-- deliberately untouched: a token created for a holder keeps the capabilities it was minted with.
--
-- $except, when set, is the id of one login row to keep.  It exists only for a self-directed
-- widening change -- accepting an invitation, granting yourself a tenant right (when you're an admin)
-- where the acting user only gains a capability and revoking their own session would log them out
-- mid-request. Admins are the ones that can grant themselves something, for example they
-- can grant themselves 'manage-user'. They already have the corresponding rights, because
-- the admin token is stronger than 'manager-user', but they can (in the UI) grant themselves
-- 'manager-user'. This is not privilege escalation.
delete from access_tokens
where user_id = $user_id
  and kind = 'login'
  and ($except::uuid is null or id <> $except)
