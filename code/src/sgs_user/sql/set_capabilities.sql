update users
set capability_trie = $capability_trie
where id = $user_id and state = 'active'
