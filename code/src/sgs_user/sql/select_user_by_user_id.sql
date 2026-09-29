select
    users.id,
    users.name,
    users.email,
    users.type,
    users.avatar_url,
    users.auth_origin,
    users.capability_trie
from users
where users.id = $user_id and users.state = 'active'
