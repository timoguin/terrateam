module Primary = struct
  module Iterations = struct
    module Items = struct
      type t = {
        duration : int;
        start_date : string;
        title : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    duration : int;
    iterations : Iterations.t option; [@default None]
    start_date : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
