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

  module Options = struct
    module Items = struct
      module Primary = struct
        module Color = struct
          let t_of_yojson = function
            | `String "blue" -> Ok `Blue
            | `String "gray" -> Ok `Gray
            | `String "green" -> Ok `Green
            | `String "orange" -> Ok `Orange
            | `String "pink" -> Ok `Pink
            | `String "purple" -> Ok `Purple
            | `String "red" -> Ok `Red
            | `String "yellow" -> Ok `Yellow
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          let t_to_yojson = function
            | `Blue -> `String "blue"
            | `Gray -> `String "gray"
            | `Green -> `String "green"
            | `Orange -> `String "orange"
            | `Pink -> `String "pink"
            | `Purple -> `String "purple"
            | `Red -> `String "red"
            | `Yellow -> `String "yellow"

          type t =
            ([ `Blue
             | `Gray
             | `Green
             | `Orange
             | `Pink
             | `Purple
             | `Red
             | `Yellow
             ]
            [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        type t = {
          color : Color.t;
          description : string option; [@default None]
          name : string;
          priority : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Visibility = struct
    let t_of_yojson = function
      | `String "all" -> Ok `All
      | `String "organization_members_only" -> Ok `Organization_members_only
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `All -> `String "all"
      | `Organization_members_only -> `String "organization_members_only"

    type t =
      ([ `All
       | `Organization_members_only
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    data_type : Data_type.t;
    description : string option; [@default None]
    name : string;
    options : Options.t option; [@default None]
    visibility : Visibility.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
