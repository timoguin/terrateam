module Scope = Sg_caps_trie_scope

(* A tenant answers the states it reaches, and a state answers the addresses it reaches. *)
type t = Scope.t Sg_caps_trie.t Sg_caps_trie.t [@@deriving show]

let equal_states = Sg_caps_trie.equal Scope.equal
let no_state = Sg_caps_trie.const Scope.empty
let empty = Sg_caps_trie.const no_state
let everything = Sg_caps_trie.const (Sg_caps_trie.const Scope.full)

let make ~(tenants : Scope.t) ~(states : Scope.t) ~(addresses : Scope.t) =
  let per_state =
    Sg_caps_trie.map
      ~equal:Scope.equal
      (fun reached -> if reached then addresses else Scope.empty)
      (states :> bool Sg_caps_trie.t)
  in
  Sg_caps_trie.map
    ~equal:equal_states
    (fun reached -> if reached then per_state else no_state)
    (tenants :> bool Sg_caps_trie.t)

let mem t ~tenant ~state ~address =
  Scope.mem (Sg_caps_trie.find (Sg_caps_trie.find t tenant) state) address

let combine f = Sg_caps_trie.merge ~equal:equal_states (Sg_caps_trie.merge ~equal:Scope.equal f)
let union = combine Scope.union
let inter = combine Scope.inter
let diff = combine Scope.diff
let is_empty = Sg_caps_trie.for_all (Sg_caps_trie.for_all Scope.is_empty)
let subset a b = is_empty (diff a b)
