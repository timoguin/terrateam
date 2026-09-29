module Unsupported_resources = struct
  type t = Sgs_api_components_unsupported_resource.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  error : string option; [@default None]
  generated_hcl : string option; [@default None]
  import_blocks : string option; [@default None]
  message : string option; [@default None]
  plan_stderr : string option; [@default None]
  plan_stdout : string option; [@default None]
  provider_hcl : string option; [@default None]
  supported_count : int;
  unsupported_count : int;
  unsupported_resources : Unsupported_resources.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
