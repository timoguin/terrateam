insert into github_users (
       user_id,
       avatar_url,
       token,
       refresh_token,
       expiration,
       refresh_expiration,
       email
)
values (
       $user_id,
       $avatar_url,
       $token,
       $refresh_token,
       $expiration,
       $refresh_expiration,
       $email
)
on conflict (user_id) do update set (
   expiration,
   refresh_expiration,
   refresh_token,
   token,
   email
) = (excluded.expiration, excluded.refresh_expiration, excluded.refresh_token, excluded.token, excluded.email)