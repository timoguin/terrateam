-- Replace a user's capabilities wholesale.  The merge happens in OCaml, because the allow-list
-- semantics -- longest match wins, a leading "!" refusing -- live in Sg_caps_trie_scope and must
-- not be reimplemented in SQL.
--
-- base_capabilities is the manually-managed baseline and capabilities the effective value login
-- recomputes from it (capabilities := base_capabilities, unioned with the IdP group rules), so a
-- grant that has to survive a sign-in must be written to both. set_instance_admin passes both;
-- grant_tenant and revoke_tenant pass null and leave the baseline as it was.  The cast is what lets
-- a json parameter meet a jsonb column inside coalesce.
--
-- Returns the id so a caller can tell a no-op (user gone or deleted between the lock and here) from
-- a successful write; a caller holding the lock from that same select already knows.
update users
set capability_trie = $capability_trie,
    base_capability_trie = coalesce($base_capability_trie::jsonb, base_capability_trie)
where id = $user_id and state = 'active'
returning id
