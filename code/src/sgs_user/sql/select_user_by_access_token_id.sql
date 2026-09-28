select
    users.id,
    users.name,
    users.email,
    users.type
from users
inner join access_tokens
    on access_tokens.user_id = users.id
where access_tokens.id = $access_token_id and users.state = 'active'
