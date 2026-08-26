(** Reusable matching for capability allow-lists.

    An allow-list is a list of glob patterns. A pattern prefixed with ['!'] is a {e negation}: it
    excludes any value it matches. A value is allowed when it matches at least one positive pattern
    and no negative pattern. Globs follow the same convention as {!Sg_node.Matcher}: ['*'] matches
    any sequence of characters (including dots), every other character is literal.

    Capability patterns are restricted to {e prefix-globs}: a literal prefix with an optional single
    {e trailing} ['*'] (the prefix is a raw character prefix, not segment/dot-aligned, so ["aws_*"]
    and ["foo*"] are valid). A ['*'] anywhere but the end, or a repeated ['*'], is rejected by
    {!is_valid_pattern} at the input boundary. {!matches} still evaluates arbitrary globs (so any
    legacy data keeps its meaning), but {!canonicalize_list}, {!subsumes} and {!intersects} only
    reduce well-formed prefix-globs and treat anything else conservatively.

    This module is intentionally decoupled from the capability record types so it can be reused
    across the different capability contexts that carry allow-lists. *)

(** [normalize_list l] applies the implicit-["*"] rule: a list whose entries are {e all} negations
    is meaningless on its own, so ["*"] is prepended (e.g. [["!a.*"]] becomes [["*"; "!a.*"]]). An
    empty list and a list with at least one positive pattern are returned unchanged. *)
val normalize_list : string list -> string list

(** [matches patterns value] is [true] when [value] is allowed by [patterns]. [patterns] is first
    run through {!normalize_list}; then [value] must match some positive pattern and no negative
    pattern. An invalid glob never matches. The empty list [[]] denies everything (no positive
    pattern), which is exactly equivalent to [["!*"]] (normalizes to [["*"; "!*"]]). *)
val matches : string list -> string -> bool

(** [canonicalize_list l] rewrites [l] into the minimal, evaluation-faithful representation used
    when persisting capabilities (so a stored list reads the way it is evaluated):
    - [[]] and any list containing ["!*"] become [["!*"]] (deny everything);
    - an all-negation list materializes the implicit ["*"] (e.g. [["!a"]] -> [["*"; "!a"]]);
    - exact duplicate entries are removed;
    - within a polarity a superset glob absorbs subsets — the universal ["*"] is just the broadest
      case (e.g. [["a"; "*"]] -> [["*"]]; [["foo.bar.*"; "foo.bar.baz.*"]] -> [["foo.bar.*"]]);
    - a negation that covers a positive removes that positive; if this empties the positives the
      result is [["!*"]] (deny all), {e not} the all-negation ["*"]-materialization (e.g.
      [["a.b.*"; "x.*"; "!a.*"]] -> [["x.*"; "!a.*"]]; [["a.*"; "!a.*"]] -> [["!*"]]);
    - a negation disjoint from every positive is dropped (e.g. [["a.*"; "!b.*"]] -> [["a.*"]]).
      [matches] yields the same result before and after [canonicalize_list]. Only well-formed
      prefix-globs are reduced; any other pattern is left untouched. *)
val canonicalize_list : string list -> string list

(** [is_valid_pattern s] is [true] when [s] is an acceptable capability pattern: at most
    {!max_pattern_length} characters and, after any leading ['!'], a literal prefix with an optional
    single {e trailing} ['*']. A mid-string ['*'] (e.g. ["a*b"], ["foo.*.bar"]) or a repeated ['*']
    (e.g. ["a**"]) is rejected. Used to validate untrusted capabilities at the input boundary. *)
val is_valid_pattern : string -> bool

(** Maximum length of a capability pattern accepted by {!is_valid_pattern}. *)
val max_pattern_length : int

(** [subsumes a b] is [true] when every value matched by glob [b] is also matched by glob [a] (i.e.
    [L(b)] ⊆ [L(a)]). Defined for prefix-globs: ["p*"] subsumes anything whose literal part begins
    with [p]; an exact literal subsumes only itself. Returns [false] for any pattern that is not a
    well-formed prefix-glob. *)
val subsumes : string -> string -> bool

(** [intersects a b] is [true] when some value is matched by both globs [a] and [b] (i.e. [L(a)] ∩
    [L(b)] is non-empty). Defined for prefix-globs. Returns [true] (assume overlap) for any pattern
    that is not a well-formed prefix-glob. *)
val intersects : string -> string -> bool

(** [is_negation s] is [true] when [s] is a negation pattern (prefixed with ['!']). *)
val is_negation : string -> bool

(** [grants_all patterns] is [true] when [patterns] permits every value: after {!normalize_list} it
    has a positive ["*"] and no negation. E.g. [["*"]] grants all; [[]], [["!*"]] and [["*"; "!a"]]
    do not. *)
val grants_all : string list -> bool

(** [lookup assoc key] selects a value from a keyed allow-list using most-specific-wins precedence:
    the entry whose key equals [key] if present, otherwise the entry keyed by ["*"], otherwise
    [None]. *)
val lookup : (string * 'a) list -> string -> 'a option
