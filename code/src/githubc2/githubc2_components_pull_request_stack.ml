module Primary = struct
  module Base = struct
    module Primary = struct
      type t = {
        ref_ : string; [@key "ref"]
        sha : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    base : Base.t;
    id : int option; [@default None]
    number : int option; [@default None]
    position : int option; [@default None]
    size : int option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
