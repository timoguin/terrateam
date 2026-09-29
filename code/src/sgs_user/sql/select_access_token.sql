select
    to_char(expiration, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    name,
    user_id,
    (expiration is not null and expiration < now()) as expired,
    capability_trie
from access_tokens
where id = $access_token_id
