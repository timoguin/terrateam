update compute_nodes set
    capabilities = $capabilities,
    updated_at = now()
where id = $compute_node_id
