module Primary = struct
  module Group_members = struct
    module Items = struct
      module Primary = struct
        module Status_ = struct
          let t_of_yojson = function
            | `String "in_progress" -> Ok `In_progress
            | `String "pending" -> Ok `Pending
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          let t_to_yojson = function
            | `In_progress -> `String "in_progress"
            | `Pending -> `String "pending"

          type t =
            ([ `In_progress
             | `Pending
             ]
            [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        type t = {
          job_html_url : string option; [@default None]
          job_id : int option; [@default None]
          job_name : string option; [@default None]
          job_url : string option; [@default None]
          run_html_url : string option; [@default None]
          run_id : int;
          run_name : string;
          run_url : string option; [@default None]
          status : Status_.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    group_members : Group_members.t;
    group_name : string;
    group_url : string;
    total_count : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
