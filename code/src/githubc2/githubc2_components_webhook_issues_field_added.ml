module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "field_added" -> Ok `Field_added
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Field_added -> `String "field_added"

    type t = ([ `Field_added ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Changes = struct
    module Primary = struct
      module Issue_field_value_ = struct
        module Primary = struct
          module From = struct
            module Primary = struct
              module Option = struct
                module Primary = struct
                  type t = {
                    color : string option; [@default None]
                    description : string option; [@default None]
                    id : int option; [@default None]
                    name : string option; [@default None]
                  }
                  [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
              end

              module Options = struct
                module Items = struct
                  module Primary = struct
                    type t = {
                      color : string option; [@default None]
                      description : string option; [@default None]
                      id : int option; [@default None]
                      name : string option; [@default None]
                    }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module Value = struct
                module V0 = struct
                  type t = string option
                  [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                module V1 = struct
                  type t = float option
                  [@@deriving yojson { strict = false; meta = true }, show, eq]
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

              module Value_ids = struct
                type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              type t = {
                id : int;
                option : Option.t option; [@default None]
                options : Options.t option; [@default None]
                value : Value.t option; [@default None]
                value_id : int option; [@default None]
                value_ids : Value_ids.t option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = { from : From.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = { issue_field_value : Issue_field_value_.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Issue_field_ = struct
    module Primary = struct
      module Field_type = struct
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

      type t = {
        field_type : Field_type.t;
        id : int;
        name : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Issue_field_value_ = struct
    module Primary = struct
      module Option = struct
        module Primary = struct
          type t = {
            color : string option; [@default None]
            description : string option; [@default None]
            id : int option; [@default None]
            name : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Options = struct
        module Items = struct
          module Primary = struct
            type t = {
              color : string option; [@default None]
              description : string option; [@default None]
              id : int option; [@default None]
              name : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
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

      module Value_ids = struct
        type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        id : int;
        option : Option.t option; [@default None]
        options : Options.t option; [@default None]
        value : Value.t option; [@default None]
        value_id : int option; [@default None]
        value_ids : Value_ids.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : Action.t;
    changes : Changes.t option; [@default None]
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    issue : Githubc2_components_webhooks_issue.t;
    issue_field : Issue_field_.t;
    issue_field_value : Issue_field_value_.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
