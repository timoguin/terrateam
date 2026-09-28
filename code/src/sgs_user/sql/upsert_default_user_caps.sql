insert into system_settings (key, value)
values ('default_user_capability_trie', $value)
on conflict (key) do update set value = excluded.value, updated_at = now()
