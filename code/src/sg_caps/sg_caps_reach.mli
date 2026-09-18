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

(** [mem t ~tenant ~state ~address] is true when [t] reaches that triple. *)
val mem : t -> tenant:string -> state:string -> address:string -> bool

(** [union a b] reaches the triples that [a] or [b] reaches. *)
val union : t -> t -> t

(** [inter a b] reaches the triples that both [a] and [b] reach. *)
val inter : t -> t -> t

(** [diff a b] reaches the triples that [a] reaches and [b] does not reach. *)
val diff : t -> t -> t

(** [subset a b] is true when [b] reaches every triple that [a] reaches. *)
val subset : t -> t -> bool

(** [is_empty t] is true when [t] reaches no triple. *)
val is_empty : t -> bool
