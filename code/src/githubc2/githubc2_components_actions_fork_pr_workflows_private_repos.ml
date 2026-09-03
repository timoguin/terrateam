module Primary = struct
  type t = {
    require_approval_for_fork_pr_workflows : bool;
    run_workflows_from_fork_pull_requests : bool;
    send_secrets_and_variables : bool;
    send_write_tokens_to_workflows : bool;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
