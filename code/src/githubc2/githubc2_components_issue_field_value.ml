module Primary = struct
  module Data_type = struct
    let t_of_yojson = function
      | `String "date" -> Ok `Date
      | `String "multi_select" -> Ok `Multi_select
      | `String "number" -> Ok `Number
      | `String "single_select" -> Ok `Single_select
      | `String "text" -> Ok `Text
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Date -> `String "date"
      | `Multi_select -> `String "multi_select"
      | `Number -> `String "number"
      | `Single_select -> `String "single_select"
      | `Text -> `String "text"

    type t =
      ([ `Date
       | `Multi_select
       | `Number
       | `Single_select
       | `Text
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Multi_select_options = struct
    module Items = struct
      module Primary = struct
        type t = {
          color : string;
          id : int64;
          name : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Single_select_option = struct
    module Primary = struct
      type t = {
        color : string;
        id : int64;
        name : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Value = struct
    module V0 = struct
      type t = string option [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module V1 = struct
      type t = float option [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module V2 = struct
      type t = int option [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t =
      | V0 of V0.t
      | V1 of V1.t
      | V2 of V2.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.any_of
        (let open CCResult in
         [
           (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
           (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
           (fun v -> map (fun v -> V2 v) (V2.of_yojson v));
         ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
      | V1 v -> V1.to_yojson v
      | V2 v -> V2.to_yojson v
  end

  type t = {
    data_type : Data_type.t;
    issue_field_id : int64;
    issue_field_name : string option; [@default None]
    multi_select_options : Multi_select_options.t option; [@default None]
    node_id : string;
    single_select_option : Single_select_option.t option; [@default None]
    value : Value.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
