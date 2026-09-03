module Primary = struct
  module Default_setting = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok `Disabled
      | `String "enabled" -> Ok `Enabled
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Disabled -> `String "disabled"
      | `Enabled -> `String "enabled"

    type t =
      ([ `Disabled
       | `Enabled
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Enterprise_setting = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok `Disabled
      | `String "enabled" -> Ok `Enabled
      | `String "not-set" -> Ok `Not_set
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Disabled -> `String "disabled"
      | `Enabled -> `String "enabled"
      | `Not_set -> `String "not-set"

    type t =
      ([ `Disabled
       | `Enabled
       | `Not_set
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Setting = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok `Disabled
      | `String "enabled" -> Ok `Enabled
      | `String "not-set" -> Ok `Not_set
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Disabled -> `String "disabled"
      | `Enabled -> `String "enabled"
      | `Not_set -> `String "not-set"

    type t =
      ([ `Disabled
       | `Enabled
       | `Not_set
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    alert_total : int option; [@default None]
    alert_total_percentage : int option; [@default None]
    bypass_rate : int option; [@default None]
    custom_pattern_version : string option; [@default None]
    default_setting : Default_setting.t option; [@default None]
    display_name : string option; [@default None]
    enterprise_setting : Enterprise_setting.t option; [@default None]
    false_positive_rate : int option; [@default None]
    false_positives : int option; [@default None]
    setting : Setting.t option; [@default None]
    slug : string option; [@default None]
    token_type : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
