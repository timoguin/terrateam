module Primary = struct
  module Requester = struct
    module Primary = struct
      type t = {
        id : int option; [@default None]
        login : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Status_ = struct
    let t_of_yojson = function
      | `String "approved" -> Ok `Approved
      | `String "cancelled" -> Ok `Cancelled
      | `String "pending" -> Ok `Pending
      | `String "rejected" -> Ok `Rejected
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Approved -> `String "approved"
      | `Cancelled -> `String "cancelled"
      | `Pending -> `String "pending"
      | `Rejected -> `String "rejected"

    type t =
      ([ `Approved
       | `Cancelled
       | `Pending
       | `Rejected
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    created_at : string option; [@default None]
    id : int option; [@default None]
    requester : Requester.t option; [@default None]
    status : Status_.t option; [@default None]
    url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
