module Primary = struct
  module Advanced_security = struct
    module Primary = struct
      module Status_ = struct
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

      type t = { status : Status_.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Code_security = struct
    module Primary = struct
      module Status_ = struct
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

      type t = { status : Status_.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Dependabot_security_updates = struct
    module Primary = struct
      module Status_ = struct
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

      type t = { status : Status_.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Secret_scanning = struct
    module Primary = struct
      module Status_ = struct
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

      type t = { status : Status_.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Secret_scanning_ai_detection = struct
    module Primary = struct
      module Status_ = struct
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

      type t = { status : Status_.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Secret_scanning_delegated_alert_dismissal = struct
    module Primary = struct
      module Status_ = struct
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

      type t = { status : Status_.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Secret_scanning_delegated_bypass = struct
    module Primary = struct
      module Status_ = struct
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

      type t = { status : Status_.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Secret_scanning_delegated_bypass_options = struct
    module Primary = struct
      module Reviewers = struct
        module Items = struct
          module Primary = struct
            module Mode = struct
              let t_of_yojson = function
                | `String "ALWAYS" -> Ok `ALWAYS
                | `String "EXEMPT" -> Ok `EXEMPT
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              let t_to_yojson = function
                | `ALWAYS -> `String "ALWAYS"
                | `EXEMPT -> `String "EXEMPT"

              type t =
                ([ `ALWAYS
                 | `EXEMPT
                 ]
                [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            module Reviewer_type = struct
              let t_of_yojson = function
                | `String "ROLE" -> Ok `ROLE
                | `String "TEAM" -> Ok `TEAM
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              let t_to_yojson = function
                | `ROLE -> `String "ROLE"
                | `TEAM -> `String "TEAM"

              type t =
                ([ `ROLE
                 | `TEAM
                 ]
                [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            type t = {
              mode : Mode.t; [@default `ALWAYS]
              reviewer_id : int;
              reviewer_type : Reviewer_type.t;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = { reviewers : Reviewers.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Secret_scanning_non_provider_patterns = struct
    module Primary = struct
      module Status_ = struct
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

      type t = { status : Status_.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Secret_scanning_push_protection = struct
    module Primary = struct
      module Status_ = struct
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

      type t = { status : Status_.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    advanced_security : Advanced_security.t option; [@default None]
    code_security : Code_security.t option; [@default None]
    dependabot_security_updates : Dependabot_security_updates.t option; [@default None]
    secret_scanning : Secret_scanning.t option; [@default None]
    secret_scanning_ai_detection : Secret_scanning_ai_detection.t option; [@default None]
    secret_scanning_delegated_alert_dismissal : Secret_scanning_delegated_alert_dismissal.t option;
        [@default None]
    secret_scanning_delegated_bypass : Secret_scanning_delegated_bypass.t option; [@default None]
    secret_scanning_delegated_bypass_options : Secret_scanning_delegated_bypass_options.t option;
        [@default None]
    secret_scanning_non_provider_patterns : Secret_scanning_non_provider_patterns.t option;
        [@default None]
    secret_scanning_push_protection : Secret_scanning_push_protection.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
