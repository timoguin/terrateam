select base_capability_trie
from users
where id = $user_id and state = 'active'
