-- How many restarts lead to the given job: 0 for a job that restarts nothing.
with recursive chain(id, restart_of, depth) as (
  select id, restart_of, 0 from jobs where id = $id
  union all
  select jobs.id, jobs.restart_of, chain.depth + 1
  from jobs
  inner join chain
    on jobs.id = chain.restart_of
)
select coalesce(max(depth), 0)::integer from chain
