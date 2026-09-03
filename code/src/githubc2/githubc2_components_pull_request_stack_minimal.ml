module Primary = struct
  module Base = struct
    module Primary = struct
      type t = { ref_ : string [@key "ref"] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Pull_requests = struct
    module Items = struct
      module Primary = struct
        module Head = struct
          module Primary = struct
            type t = {
              ref_ : string; [@key "ref"]
              sha : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module State = struct
          let t_of_yojson = function
            | `String "closed" -> Ok `Closed
            | `String "open" -> Ok `Open
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          let t_to_yojson = function
            | `Closed -> `String "closed"
            | `Open -> `String "open"

          type t =
            ([ `Closed
             | `Open
             ]
            [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        type t = {
          draft : bool;
          head : Head.t;
          merged_at : string option; [@default None]
          number : int;
          state : State.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    base : Base.t;
    created_at : string;
    id : int;
    node_id : string;
    number : int;
    open_ : bool; [@key "open"]
    pull_requests : Pull_requests.t;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
