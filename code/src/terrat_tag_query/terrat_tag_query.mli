module Ctx : sig
  type t

  (** [working_dirspace] is the dirspace that is currently being evaluated. This is necessary to use
      [relative_dir] in the tag query. *)
  val make : ?working_dirspace:Terrat_dirspace.t -> dirspace:Terrat_dirspace.t -> unit -> t
end

type t [@@deriving show, eq]

(** A query that parsed but was written in a way worth telling the user about.

    [Implicit_and] means two expressions were separated by whitespace alone, which is an [and].
    [suggestion] is the same query with every operand joined by [or], and is only present when the
    query is made of nothing but directory selectors: [dir:a dir:b] and [dir:a or dir:b dir:c]
    cannot match every directory named, so [or] is certainly what was meant, while
    [dir:a workspace:prod] is a sensible [and] and gets no rewrite. *)
type warning = Implicit_and of { suggestion : string option } [@@deriving show]

val of_string : string -> (t, [> Terrat_tag_query_ast.err ]) result
val to_string : t -> string

(** The warning, if any, the query was parsed with. It stays on the query rather than being returned
    by {!of_string} so that it survives a round trip through storage, and so that only the call
    points that act on a warning have to know it exists. *)
val warning : t -> warning option

(** [dirspace] is used in tests against the [dir] and [workspace] and [in dir] tests. *)
val match_ : ctx:Ctx.t -> tag_set:Terrat_tag_set.t -> t -> bool

(** A pre-defined matcher that matches anything, equivalent to [of_string ""] *)
val any : t
