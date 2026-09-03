module Primary = struct
  module Checks = struct
    module Items = struct
      module Primary = struct
        module App = struct
          module Primary = struct
            type t = {
              id : int option; [@default None]
              name : string option; [@default None]
              slug : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          app : App.t option; [@default None]
          context : string option; [@default None]
          id : int option; [@default None]
          state : string option; [@default None]
          type_ : string option; [@default None] [@key "type"]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = { checks : Checks.t option [@default None] }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
