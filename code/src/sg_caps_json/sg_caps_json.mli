(** Reading and writing {!Sg_caps} as declared by the API schema.

    A scope is written as its rules. A reach is written as the tenant rules, each carrying the state
    rules reached there, each carrying the addresses reached in those states; a tenant or state rule
    is a pattern alone.

    {v
      { "access-token-create": true, "access-token-refresh": false,
        "admin": [], "users-manage": [], "sudo": [],
        "commit": { "modified": [ { "tenant": "*",
                                    "states": [ { "state": "s1", "addresses": [ "a.*", "!a.b" ] } ] } ],
                    "pulled-in": [ ... ] },
        "preview": { ... } }
    v} *)

(** [to_wire caps] writes [caps]. The rules it writes are the ones {!Sg_caps_trie_scope.to_rules}
    gives, so capability sets that allow the same atoms are written the same way. *)
val to_wire : Sg_caps.t -> Sg_caps_wire_capabilities.t

(** Why a wire cannot be read: a text that is not a pattern, or more rules at one place than reading
    accepts, as [(place, count, limit)]. *)
type read_err =
  [ `Invalid_pattern_err of string
  | `Too_many_rules_err of string * int * int
  ]
[@@deriving show]

(** [of_wire wire] reads back what {!to_wire} writes. *)
val of_wire : Sg_caps_wire_capabilities.t -> (Sg_caps.t, [> read_err ]) result
