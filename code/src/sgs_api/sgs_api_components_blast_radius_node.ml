module Instance_addresses = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  address : string;
  id : string;
  instance_addresses : Instance_addresses.t;
  instance_count : int;
  is_seed : bool;
  kind : string;
  module_address : string;
  resource_type : string option; [@default None]
  state_id : string;
  state_name : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
