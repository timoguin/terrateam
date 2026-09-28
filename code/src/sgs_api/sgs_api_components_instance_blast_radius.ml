module Edges = struct
  type t = Sgs_api_components_blast_radius_edge.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Nodes = struct
  type t = Sgs_api_components_blast_radius_node.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  edges : Edges.t;
  nodes : Nodes.t;
  root_id : string;
  total_nodes : int;
  truncated : bool;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
