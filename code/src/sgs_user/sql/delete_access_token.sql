delete from access_tokens
where id = $token_id and user_id = $user_id
returning id
