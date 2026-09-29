type t = {
  task : Sgs_api_components_task.t;
  token : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
