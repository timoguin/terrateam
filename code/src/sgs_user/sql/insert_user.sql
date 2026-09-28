insert into users (email, name, type, capability_trie, base_capability_trie)
values ($email, $name, $type, $capability_trie, $capability_trie)
returning id
