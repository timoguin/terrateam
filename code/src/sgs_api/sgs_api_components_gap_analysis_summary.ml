type t = {
  managed_by_stategraph : int;
  phantom_filtered : int option; [@default None]
  total_aws_resources : int option; [@default None]
  total_cloud_resources : int option; [@default None]
  unmanaged : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
