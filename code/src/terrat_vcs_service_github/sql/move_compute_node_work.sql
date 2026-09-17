-- Move a work manifest from the node that owes it to another node.  The index
-- compute_node_work_work_manifest_idx is unique on work_manifest, so a work
-- manifest has one node and one row: it moves, it is never copied.
update compute_node_work set
    compute_node = $compute_node_id,
    state = 'created'
where work_manifest = $work_manifest
