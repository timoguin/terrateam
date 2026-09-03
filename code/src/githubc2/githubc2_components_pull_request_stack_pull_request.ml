module All_of = struct
  module Primary = struct
    module Base = struct
      module Primary = struct
        module Repo = struct
          module Primary = struct
            type t = {
              id : int64;
              name : string;
              url : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          ref_ : string; [@key "ref"]
          repo : Repo.t;
          sha : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Head = struct
      module Primary = struct
        module Repo = struct
          module Primary = struct
            type t = {
              id : int64;
              name : string;
              url : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          ref_ : string; [@key "ref"]
          repo : Repo.t;
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
      base : Base.t;
      draft : bool;
      head : Head.t;
      html_url : string;
      id : int64;
      merged_at : string option; [@default None]
      node_id : string;
      number : int;
      state : State.t;
      title : string;
      url : string;
      user : Githubc2_components_nullable_simple_user.t option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module T = struct
  module Primary = struct
    module Base = struct
      module Primary = struct
        module Repo = struct
          module Primary = struct
            type t = {
              id : int64;
              name : string;
              url : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          ref_ : string; [@key "ref"]
          repo : Repo.t;
          sha : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Head = struct
      module Primary = struct
        module Repo = struct
          module Primary = struct
            type t = {
              id : int64;
              name : string;
              url : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          ref_ : string; [@key "ref"]
          repo : Repo.t;
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
      base : Base.t;
      draft : bool;
      head : Head.t;
      html_url : string;
      id : int64;
      merged_at : string option; [@default None]
      node_id : string;
      number : int;
      state : State.t;
      title : string;
      url : string;
      user : Githubc2_components_nullable_simple_user.t option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

let of_yojson json =
  let open CCResult in
  flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
