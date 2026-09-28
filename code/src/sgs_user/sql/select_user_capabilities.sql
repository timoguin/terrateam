-- The capabilities of the active users the caller is asking about.
--
-- Deliberately free of any jsonb inspection: what makes a capability an installation-wide admin
-- grant is decided once, in Sg_caps_ops.is_instance_admin, rather than restated here in a form
-- that could drift from it.  This query's whole job is to say which rows the question is asked
-- about.
--
-- $user_id null  : every active human user.  The population the last-admin guards count, and the
--                  one the sign-up bootstrap tests for having no administrator.  'api' and 'system'
--                  rows are left out: what both callers want to know is how many *people* can
--                  administer the installation.
-- $user_id given : that one user, whatever their type -- the endpoints take a user id from the
--                  caller and must answer about exactly it -- or no row at all when no active user
--                  has that id, which they answer with 404.
select capability_trie
from users
where state = 'active'
  and ($user_id::uuid is null or id = $user_id::uuid)
  and ($user_id::uuid is not null or type = 'user')
