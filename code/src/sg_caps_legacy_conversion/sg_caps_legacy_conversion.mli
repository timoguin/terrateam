(** Reading the capability record stored as JSON ([Sgs_session_caps_capabilities]) as the capability
    set of the new model ({!Sg_caps}).

    The two say the same thing about every tenant, state and address a request can carry, with three
    differences, each of them a decision rather than an accident:

    - An [admin] grant now answers for preview and commit. The old record refused an action whose
      key was absent even to an administrator, so a record holding [admin] and no [commit] comes out
      now grants more than it did.
    - A capability that reaches nothing is a capability that is not there. The old record kept the
      two apart -- [{"tenants": []}] granted nothing yet still read as "is an administrator" -- and
      an empty scope cannot carry that.
    - The old matcher never matched the empty string, not even against ["*"]; an empty tenant, state
      or address is now reached by a grant that reaches everything. No such value exists anyway so
      this doesn't change behavior. *)

(** [convert caps] reads [caps]. It fails on a pattern the new model cannot hold: a ['*'] that is
    not the last character, a character below 32, or a state key holding a ['*'] -- a key is matched
    by equality, so only the key ["*"] itself is a pattern there.

    {v
      convert {commit = {tenants = ["t1"]; states = None; subgraph = None}}
        reaches every state and every address of t1, and nothing of t2

      convert {commit = {states = {"s1": ["a.*"; "!a.b"]}}}
        reaches a.c of s1, and neither a.b of s1 nor anything of s2

      convert {commit = {states = {"*": ["a.*"], "s1": ["b"]}}}
        reaches b of s1, a.c of s2, and not a.c of s1

      convert {admin = {tenants = ["t1"]}}
        commits and previews over t1, which the old record refused

      convert {commit = {tenants = ["a*b"]}}
        = Error (`Invalid_pattern_err "a*b")
    v} *)
val convert :
  Sgs_session_caps_capabilities.t -> (Sg_caps.t, [> `Invalid_pattern_err of string ]) result
