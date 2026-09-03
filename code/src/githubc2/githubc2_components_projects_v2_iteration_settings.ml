module Primary = struct
  module Title = struct
    module Primary = struct
      type t = {
        html : string;
        raw : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    completed : bool;
    duration : int;
    id : string;
    start_date : string;
    title : Title.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
