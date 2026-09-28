select
    at.id,
    at.name,
    to_char(at.created_at, 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
    to_char(at.expiration, 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
    u.id,
    u.name,
    u.type
from access_tokens at
join users u on u.id = at.user_id
where at.kind = 'api'
  and (at.expiration is null or at.expiration > now())
order by at.created_at desc
