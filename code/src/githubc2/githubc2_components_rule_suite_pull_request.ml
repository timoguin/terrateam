module Primary = struct
  module Pull_request_ = struct
    module Primary = struct
      module Reviews = struct
        module Items = struct
          module Primary = struct
            module User = struct
              module Primary = struct
                type t = {
                  id : int option; [@default None]
                  login : string option; [@default None]
                  type_ : string option; [@default None] [@key "type"]
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = {
              id : int option; [@default None]
              state : string option; [@default None]
              user : User.t option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module User = struct
        module Primary = struct
          type t = {
            id : int option; [@default None]
            login : string option; [@default None]
            type_ : string option; [@default None] [@key "type"]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        id : int option; [@default None]
        number : int option; [@default None]
        reviews : Reviews.t option; [@default None]
        user : User.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = { pull_request : Pull_request_.t option [@default None] }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
