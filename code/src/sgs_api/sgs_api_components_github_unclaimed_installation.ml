type t = {
  created_at : string;
  github_id : int;
  installation_core_id : string;
  login : string;
  state : string;
  target_type : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
