-- Pin the AFTER-INSERT trigger function's search_path. It is SECURITY INVOKER
-- and references gitlab_installations_map unqualified, so it resolves the
-- table through the caller's session search_path and breaks for any caller
-- whose session path excludes public -- notably a postgres_fdw remote
-- session, which forces the search_path to pg_catalog only. Pinning the
-- function's own search_path makes it robust to any caller's session path
-- (also the standard defence against search-path hijacking). Backwards
-- compatible: identical behaviour for every existing caller.
alter function insert_gitlab_installations_map() set search_path = public, pg_catalog;
