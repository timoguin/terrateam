module Caps = Sgs_session_caps_capabilities
module Scope = Sg_caps_trie_scope
module Reach = Sg_caps_reach

(* An allow-list allows a value when one of its patterns matches it and none of its negations does,
   whatever their order. That is the positives minus the negatives choice of the old system,
   and not the same list read as longest-prefix rules: ["a.b.c"; "!a.*"] refuses [a.b.c],
   whereas the most specific rule allows it.

   This function is how we translate old caps into the new ones, but generating a trie-caps that
   answer the same as the old one. *)
let scope_of_patterns patterns =
  let open CCResult.Infix in
  let scope texts =
    CCResult.map_l Sg_caps_trie.Pattern.of_string texts
    >|= fun patterns -> Scope.of_rules (CCList.map (fun p -> (p, true)) patterns)
  in
  let negations, positives =
    CCList.partition Sg_caps_match.is_negation (Sg_caps_match.normalize_list patterns)
  in
  scope positives
  >>= fun allowed ->
  scope (CCList.map (CCString.drop 1) negations) >|= fun refused -> Scope.diff allowed refused

(* An absent list used to be the unrestricted grant, see e.g. [Sg_capabilities_ops.state_resources]
   for states. *)
let scope_of_patterns_opt = CCOption.map_or ~default:(Ok Scope.full) scope_of_patterns

(* The states a key names. A key is matched by equality rather than as a pattern. The only
   glob matching for states was the key '*', whose meaning was "for all not-named states, apply these rights",
   and this handling of '*' is done by [reach_of_states] below. *)
let scope_of_state_key key =
  let open CCResult.Infix in
  match CCString.index_opt key '*' with
  | Some _ -> Error (`Invalid_pattern_err key)
  | None -> Sg_caps_trie.Pattern.of_string key >|= fun p -> Scope.of_rules [ (p, true) ]

(* The reach of one axis of a preview or commit grant: the tenants it names, the states of its map,
   and for each state the addresses that state resolves to.  An absent map reaches every address of
   every state. *)
let reach_of_states ~tenants states =
  let open CCResult.Infix in
  match states with
  | None -> Ok (Reach.make ~tenants ~states:Scope.full ~addresses:Scope.full)
  | Some states ->
      (* Examples of data handled here:

         {v
             {"s1": ["a.*"], "s2": null}   named = [("s1", Some ["a.*"]); ("s2", None)]   fallback = []
             {"*": ["a.*"], "s1": ["b"]}   named = [("s1", Some ["b"])]                   fallback = [("*", Some ["a.*"])]
             {}                            named = []                                     fallback = []
         }*)
      let entries = Sln_map.String.to_list (Sgs_session_caps_states.additional states) in
      let named, fallback = CCList.partition (fun (k, _) -> not (CCString.equal "*" k)) entries in
      (* Every state answers the ["*"] entry, or nothing at all when the map has none. A named
         state then replaces that answer for itself alone: it is taken out of the states reached so
         far, over every tenant so that nothing of it is left, and put back with its own
         addresses. *)
      CCOption.map_or
        ~default:(Ok Scope.empty)
        (fun (_star, value_mapped_by_star) -> scope_of_patterns_opt value_mapped_by_star)
        (CCList.head_opt fallback)
      >>= fun default ->
      CCList.fold_left
        (fun acc (state_name, state_addresses) ->
          acc
          >>= fun acc ->
          scope_of_state_key state_name
          >>= fun state ->
          scope_of_patterns_opt state_addresses
          >|= fun addresses ->
          Reach.union
            (Reach.diff acc (Reach.make ~tenants:Scope.full ~states:state ~addresses:Scope.full))
            (Reach.make ~tenants ~states:state ~addresses))
        (Ok (Reach.make ~tenants ~states:Scope.full ~addresses:default))
        named

(* An absent preview or commit reaches nothing. The old model denied the action outright in that
   case, even to an administrator; the new one lets the [admin] scope answer for it. *)
let actions_of ~states ~subgraph ~tenants =
  let open CCResult.Infix in
  scope_of_patterns_opt tenants
  >>= fun tenants ->
  reach_of_states ~tenants states
  >>= fun modified ->
  reach_of_states ~tenants subgraph >|= fun pulled_in -> { Sg_caps.modified; pulled_in }

let no_actions = { Sg_caps.modified = Reach.empty; pulled_in = Reach.empty }

let commit_of = function
  | None -> Ok no_actions
  | Some { Sgs_session_caps_commit.states; subgraph; tenants } ->
      actions_of ~states ~subgraph ~tenants

let preview_of = function
  | None -> Ok no_actions
  | Some { Sgs_session_caps_preview.states; subgraph; tenants } ->
      actions_of ~states ~subgraph ~tenants

(* A capability that is absent grants nothing, which is the empty scope. *)
let tenants_of = function
  | None -> Ok Scope.empty
  | Some tenants -> scope_of_patterns_opt tenants

let granted = CCOption.map_or ~default:false CCFun.id

let convert caps =
  let open CCResult.Infix in
  tenants_of (CCOption.map (fun a -> a.Sgs_session_caps_admin.tenants) caps.Caps.admin)
  >>= fun admin ->
  tenants_of
    (CCOption.map (fun u -> u.Sgs_session_caps_users_manage.tenants) caps.Caps.users_manage)
  >>= fun users_manage ->
  CCOption.map_or
    ~default:(Ok Scope.empty)
    (fun s -> scope_of_patterns s.Sgs_session_caps_sudo.users)
    caps.Caps.sudo
  >>= fun sudo ->
  commit_of caps.Caps.commit
  >>= fun commit ->
  preview_of caps.Caps.preview
  >|= fun preview ->
  {
    Sg_caps.access_token_create = granted caps.Caps.access_token_create;
    access_token_refresh = granted caps.Caps.access_token_refresh;
    admin;
    users_manage;
    sudo;
    commit;
    preview;
  }
