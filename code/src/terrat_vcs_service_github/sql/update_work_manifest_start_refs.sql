update work_manifests
set start_sha = $start_sha, start_dest_sha = $start_dest_sha
where id = $id
