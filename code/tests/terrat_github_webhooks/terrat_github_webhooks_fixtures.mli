(** JSON fixtures for the GitHub webhook decode tests. [base_payload] is the delivery GitHub makes
    for a comment a person writes on a pull request, and [app_payload] is a
    [performed_via_github_app] object. The tests edit them with the helpers below.

    Both carry members the schema does not declare -- [user_view_type], [client_id], [minimized],
    [archived_at], [archived_by], [has_pull_requests], [pull_request_creation_policy]. GitHub sends
    them, every generated type is [strict = false], and that is what these members hold. Removing
    one because the schema has no matching field removes the only cover for that tolerance. *)

val app_payload : string
val base_payload : string
val json_of_string : string -> Yojson.Safe.t
val remove_member : string -> Yojson.Safe.t -> Yojson.Safe.t
val set_member : string -> Yojson.Safe.t -> Yojson.Safe.t -> Yojson.Safe.t
val update_member : string -> (Yojson.Safe.t -> Yojson.Safe.t) -> Yojson.Safe.t -> Yojson.Safe.t
