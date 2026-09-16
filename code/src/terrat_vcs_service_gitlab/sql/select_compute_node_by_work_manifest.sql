select
    cn.id,
    cn.state,
    cn.capabilities,
    to_char(cn.created_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"'),
    to_char(cn.updated_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"')
from compute_nodes as cn
inner join compute_node_work as cnw on cnw.compute_node = cn.id
where cnw.work_manifest = $work_manifest_id
for update of cn
