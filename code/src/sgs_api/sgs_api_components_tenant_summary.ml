module Orphaned_by_state = struct
  module Items = struct
    type t = {
      count : int;
      state_name : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Orphaned_top = struct
  module Items = struct
    type t = {
      address : string;
      state_name : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Provider_distribution = struct
  module Items = struct
    type t = {
      instances : int;
      provider : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Resource_type_distribution = struct
  module Items = struct
    type t = {
      instances : int;
      type_ : string; [@key "type"]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  dependency_hotspot_address : string;
  dependency_hotspot_refs : int;
  graph_leaves : int;
  graph_roots : int;
  largest_module : string;
  largest_module_resource_count : int;
  most_deployed_module : string;
  most_deployed_module_instance_count : int;
  orphaned_by_state : Orphaned_by_state.t;
  orphaned_count : int;
  orphaned_top : Orphaned_top.t;
  provider_distribution : Provider_distribution.t;
  resource_type_distribution : Resource_type_distribution.t;
  top_resource_type : string;
  top_resource_type_count : int;
  total_edges : int;
  total_instances : int;
  total_modules : int;
  total_providers : int;
  total_resources : int;
  total_states : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
