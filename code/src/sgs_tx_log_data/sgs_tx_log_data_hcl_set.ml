module Block_type = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Data = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Depends_on_addresses = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Edges = struct
  type t = Sgs_tx_log_data_edge.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module File_refs = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Module_input_refs = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Module_inputs = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Module_source = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Path_attrs = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Refs = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Remote_state = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Remote_tf_state_refs = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  block_type : Block_type.t;
  data : Data.t;
  depends_on_addresses : Depends_on_addresses.t;
  edges : Edges.t;
  file : string;
  file_refs : File_refs.t;
  fq_address : string;
  hints : Sgs_tx_log_hints_stored_hints.t option; [@default None]
  module_ : string; [@key "module"]
  module_input_refs : Module_input_refs.t;
  module_inputs : Module_inputs.t;
  module_source : Module_source.t;
  moved_from_fq_address : string option; [@default None]
  moved_from_keyed_address : string option; [@default None]
  moved_to_fq_address : string option; [@default None]
  moved_to_keyed_address : string option; [@default None]
  node_id : string;
  path_attrs : Path_attrs.t option; [@default None]
  refs : Refs.t;
  remote_state : Remote_state.t;
  remote_tf_state_refs : Remote_tf_state_refs.t;
  unconditional_seed : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
