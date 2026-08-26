(** Reason a capability record was rejected. Each variant names the exact offending entry so the
    caller can report precisely what failed. *)
type err =
  | Invalid_pattern_err of string  (** the pattern is not a well-formed prefix-glob *)
  | Pattern_too_long_err of string  (** the pattern exceeds {!Sg_caps_match.max_pattern_length} *)
  | Too_many_patterns_err of int  (** a single allow-list exceeds {!max_patterns_per_list} *)
[@@deriving show]

(** [validate caps] is [Ok ()] when every capability allow-list in [caps] contains only well-formed
    patterns (see {!Sg_caps_match.is_valid_pattern}) and no single list exceeds
    {!max_patterns_per_list} entries. Otherwise it returns the first failure, naming the offending
    pattern (or list size). Used to reject untrusted capabilities at the input boundary (token /
    user creation) before they are stored. A [null] state value ("all resources") carries no
    patterns and is always accepted. *)
val validate : Sgs_session_caps_capabilities.t -> (unit, err) result

(** Maximum number of patterns allowed in a single capability allow-list. *)
val max_patterns_per_list : int
