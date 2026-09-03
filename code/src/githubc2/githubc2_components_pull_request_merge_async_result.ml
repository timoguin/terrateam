module Details = struct
  module Primary = struct
    type t = {
      expected_head_sha : string option; [@default None]
      merge_action : string option; [@default None]
      merge_method : string option; [@default None]
      message : string option; [@default None]
      sha : string option; [@default None]
      uuid : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Status_ = struct
  let t_of_yojson = function
    | `String "enqueued" -> Ok `Enqueued
    | `String "failed" -> Ok `Failed
    | `String "merged" -> Ok `Merged
    | `String "pending" -> Ok `Pending
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Enqueued -> `String "enqueued"
    | `Failed -> `String "failed"
    | `Merged -> `String "merged"
    | `Pending -> `String "pending"

  type t =
    ([ `Enqueued
     | `Failed
     | `Merged
     | `Pending
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  details : Details.t;
  status : Status_.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
