type t =
  | Apply of { tag_query : Terrat_tag_query.t }
  | Apply_autoapprove of { tag_query : Terrat_tag_query.t }
  | Apply_force of { tag_query : Terrat_tag_query.t }
  | Feedback of string
  | Gate_approval of { tokens : string list }
  | Help
  | Index
  | Plan of { tag_query : Terrat_tag_query.t }
  | Repo_config
  | Unlock of string list

type err =
  [ `Not_terrateam
  | `Unknown_action of string
  | Terrat_tag_query_ast.err
  ]
[@@deriving show]

val parse : string -> (t, [> err ]) result
val to_string : t -> string

(** Closes [body] with a hidden marker. Neither GitHub nor GitLab render the marker, so it is how a
    comment published by this system is recognized when it comes back as an event. Every comment
    published on a pull request goes through here. *)
val add_self_marker : string -> string

(** [true] when [body] was published by this system, that is, when {!add_self_marker} closed it. A
    quoted copy of such a comment is not a match, because the quote does not close the body.
    Comments published before the marker existed are not matched either. *)
val is_from_self : string -> bool
