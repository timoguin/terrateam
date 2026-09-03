module Primary = struct
  module Concurrency_groups = struct
    module Items = struct
      module Primary = struct
        type t = {
          group_name : string;
          group_url : string;
          last_acquired_at : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    concurrency_groups : Concurrency_groups.t;
    total_count : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
