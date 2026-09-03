module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "add_assignee" -> Ok `Add_assignee
      | `String "add_field" -> Ok `Add_field
      | `String "add_label" -> Ok `Add_label
      | `String "close_issue" -> Ok `Close_issue
      | `String "set_type" -> Ok `Set_type
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Add_assignee -> `String "add_assignee"
      | `Add_field -> `String "add_field"
      | `Add_label -> `String "add_label"
      | `Close_issue -> `String "close_issue"
      | `Set_type -> `String "set_type"

    type t =
      ([ `Add_assignee
       | `Add_field
       | `Add_label
       | `Close_issue
       | `Set_type
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Confidence = struct
    let t_of_yojson = function
      | `String "HIGH" -> Ok `HIGH
      | `String "LOW" -> Ok `LOW
      | `String "MEDIUM" -> Ok `MEDIUM
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `HIGH -> `String "HIGH"
      | `LOW -> `String "LOW"
      | `MEDIUM -> `String "MEDIUM"

    type t =
      ([ `HIGH
       | `LOW
       | `MEDIUM
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module State = struct
    let t_of_yojson = function
      | `String "applied" -> Ok `Applied
      | `String "approved" -> Ok `Approved
      | `String "dismissed" -> Ok `Dismissed
      | `String "invalidated" -> Ok `Invalidated
      | `String "pending" -> Ok `Pending
      | `String "replaced" -> Ok `Replaced
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Applied -> `String "applied"
      | `Approved -> `String "approved"
      | `Dismissed -> `String "dismissed"
      | `Invalidated -> `String "invalidated"
      | `Pending -> `String "pending"
      | `Replaced -> `String "replaced"

    type t =
      ([ `Applied
       | `Approved
       | `Dismissed
       | `Invalidated
       | `Pending
       | `Replaced
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Target_value = struct
    module V0 = struct
      type t = string option [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module V1 = struct
      type t = float option [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module V2 = struct
      type t = bool option [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module V3 = struct
      type t = string list option [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t =
      | V0 of V0.t
      | V1 of V1.t
      | V2 of V2.t
      | V3 of V3.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
         [
           (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
           (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
           (fun v -> map (fun v -> V2 v) (V2.of_yojson v));
           (fun v -> map (fun v -> V3 v) (V3.of_yojson v));
         ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
      | V1 v -> V1.to_yojson v
      | V2 v -> V2.to_yojson v
      | V3 v -> V3.to_yojson v
  end

  type t = {
    action : Action.t;
    actor_id : int option; [@default None]
    confidence : Confidence.t option; [@default None]
    created_at : string;
    id : int;
    issue_event_id : int option; [@default None]
    issue_id : int;
    rationale : string option; [@default None]
    resolved_by : int option; [@default None]
    state : State.t;
    target_id : int option; [@default None]
    target_value : Target_value.t option; [@default None]
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
