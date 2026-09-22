(** Reading and writing {!Sg_caps} as declared by the API schema, that is as the JSON of
    [api_schemas/stategraph/capability-wire.json].

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

(** The errors reading a capability set can give: a text that is not a pattern (a ['*'] that is not
    the last character, or a character below 32), more rules at one place than {!of_wire} accepts,
    as [(place, count, limit)], and JSON that is not a capabilities object at all. *)
type read_err =
  [ `Invalid_pattern_err of string
  | `Too_many_rules_err of string * int * int
  | `Malformed_err of string
  ]
[@@deriving show]

(** A sentence naming what was wrong, for the endpoints that answer [400]. *)
val read_err_to_string : read_err -> string

(** [of_wire wire] reads back what {!to_wire} writes. It fails on a text that is not a pattern, and
    on more rules at one place than it accepts -- what arrives here is untrusted, is stored, and is
    read on every request its holder makes. *)
val of_wire :
  Sg_caps_wire_capabilities.t ->
  ( Sg_caps.t,
    [> `Invalid_pattern_err of string | `Too_many_rules_err of string * int * int ] )
  result

(** [to_json caps] is [caps] as the JSON a [capability_trie] column holds. *)
val to_json : Sg_caps.t -> Yojson.Safe.t

(** [of_json json] reads back what {!to_json} writes, failing as {!of_wire} does and on JSON that is
    not a capabilities object at all. *)
val of_json : Yojson.Safe.t -> (Sg_caps.t, [> read_err ]) result

(** {!to_json} and {!of_json} under the names [[@@deriving yojson]] looks for, so a record holding a
    capability set derives its own codec. Reading gives the sentence {!read_err_to_string} writes,
    which is all a derived codec can carry. *)
type t = Sg_caps.t [@@deriving yojson]
