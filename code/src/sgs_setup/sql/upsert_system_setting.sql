insert into system_settings (key, value, updated_at)
values ($key, $value, now())
on conflict (key) do update set value = $value, updated_at = now()
