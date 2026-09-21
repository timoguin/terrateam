(** Generators of capability values, for the property tests that need arbitrary ones.

    The alphabet is small, so that generated patterns often overlap and the properties meet the
    cases where one rule sits inside another. *)

(** Text drawn from ['a'], ['b'], ['c'] and ['.'], at most two characters. *)
val text : string QCheck2.Gen.t

(** A pattern over {!text}, literal or prefix. *)
val pattern : Sg_caps_trie.Pattern.t QCheck2.Gen.t

(** A scope of at most three rules. *)
val scope : Sg_caps_trie_scope.t QCheck2.Gen.t

(** A reach: the union of at most two products, the shape a user's capabilities take once the grants
    of several group rules are joined. *)
val reach : Sg_caps_reach.t QCheck2.Gen.t

(** The two axes of a preview or commit grant. *)
val actions : Sg_caps.actions QCheck2.Gen.t

(** A whole capability set. *)
val caps : Sg_caps.t QCheck2.Gen.t
