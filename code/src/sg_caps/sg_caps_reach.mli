(** What a preview or commit grant reaches: the (tenant, state, address) triples it allows.

    A single grant names a tenant scope, a state scope and an address scope, which {!make} turns
    into the triples of their product. The union of two grants is not a product -- one grant may
    reach the states of one tenant and the other grant other states of another tenant -- so a reach
    is a trie of tenants whose answers are tries of states whose answers are address scopes. Every
    operation is then exact: no combination of tenant, state and address appears that neither side
    allows. *)

type t [@@deriving show]

(** Reaches no triple: [mem] is false whatever the tenant, the state and the address. *)
val empty : t

(** Reaches every triple: [mem] is true whatever the tenant, the state and the address. *)
val everything : t

(** [make ~tenants ~states ~addresses] reaches the triples whose tenant is in [tenants], whose state
    is in [states] and whose address is in [addresses].

    {v
      make ~tenants:(scope [ "t1" ]) ~states:(scope [ "s1" ]) ~addresses:(scope [ "aws_instance.*" ])

        mem ~tenant:"t1" ~state:"s1" ~address:"aws_instance.web"  = true
        mem ~tenant:"t2" ~state:"s1" ~address:"aws_instance.web"  = false
    v} *)
val make :
  tenants:Sg_caps_trie_scope.t -> states:Sg_caps_trie_scope.t -> addresses:Sg_caps_trie_scope.t -> t

(** [to_rules t] gives, for each tenant rule, the state rules reached in those tenants, each with
    the addresses reached in those states. A tenant or state rule carries no refusal of its own:
    what it answers is the states, or the addresses, reached there.

    At each level, the rules start with the [*] rule, which answers for the tenants, or the states,
    that no other rule names. {!of_rules} reads its absence as "nothing reached", so [to_rules]
    leaves it out whenever that is what it would answer, to avoid emitting a useless rule.

    {v
      to_rules empty = []

      to_rules (make ~tenants:(of_strings ["t1"]) ~states:full ~addresses:(of_strings ["a.*"]))
        = [ (Literal "t1", [ (Prefix "", of_strings ["a.*"]) ]) ]
    v} *)
val to_rules :
  t -> (Sg_caps_trie.Pattern.t * (Sg_caps_trie.Pattern.t * Sg_caps_trie_scope.t) list) list

(** [of_rules rules] is the reach whose rules are [rules]: the most specific tenant rule that
    matches decides which state rules apply, and the most specific of those decides the addresses.
    It reads back what {!to_rules} writes. *)
val of_rules :
  (Sg_caps_trie.Pattern.t * (Sg_caps_trie.Pattern.t * Sg_caps_trie_scope.t) list) list -> t

(** [state_rules t ~tenant] is the state rules that apply in [tenant]: the most specific one that
    matches a state decides the addresses reached there. Always starts with [Prefix ""], the answer
    for the states no other rule names. *)
val state_rules : t -> tenant:string -> (Sg_caps_trie.Pattern.t * Sg_caps_trie_scope.t) list

(** [addresses t ~tenant ~state] is the addresses reached in that state of that tenant. *)
val addresses : t -> tenant:string -> state:string -> Sg_caps_trie_scope.t

(** [mem t ~tenant ~state ~address] is true when [t] reaches that triple. *)
val mem : t -> tenant:string -> state:string -> address:string -> bool

(** [union a b] reaches the triples that [a] or [b] reaches. *)
val union : t -> t -> t

(** [inter a b] reaches the triples that both [a] and [b] reach. *)
val inter : t -> t -> t

(** [diff a b] reaches the triples that [a] reaches and [b] does not reach. *)
val diff : t -> t -> t

(** [entails a b] is true when [a] reaches every triple that [b] reaches.

    {v
      wide   = make ~tenants:(of_strings ["t*"]) ~states:full ~addresses:full
      narrow = make ~tenants:(of_strings ["t1"]) ~states:(of_strings ["s1"]) ~addresses:full

        entails wide narrow = true
        entails narrow wide = false
    v} *)
val entails : t -> t -> bool

(** [is_empty t] is true when [t] reaches no triple. *)
val is_empty : t -> bool
