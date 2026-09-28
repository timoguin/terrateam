insert into access_tokens (capability_trie, expiration, kind, name, user_id) values($capability_trie, $expiration, $kind, $name, $user_id)
returning id
