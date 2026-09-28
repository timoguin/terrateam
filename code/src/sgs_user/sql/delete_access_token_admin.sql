delete from access_tokens
where id = $token_id
returning id
