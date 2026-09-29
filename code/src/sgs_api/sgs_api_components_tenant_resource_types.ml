module Resource_types = struct
  module Items = struct
    type t = {
      instance_count : int;
      resource_count : int;
      state_id : string;
      state_name : string;
      type_ : string; [@key "type"]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  resource_types : Resource_types.t;
  total_instances : int;
  total_resources : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
