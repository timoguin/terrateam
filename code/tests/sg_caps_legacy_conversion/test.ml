(* Tests of [Sg_caps_legacy_conversion]: the capability set it reads answers what the stored record answered.
   The oracle is the legacy check itself -- the [Sg_capabilities_ops] functions the SQL check is
   differential-tested against -- carrying the one decision the conversion takes: an [admin] grant
   answers for preview and commit even when the action key is absent. *)

module New_caps = Sg_caps
module Old_caps = Sgs_session_caps_capabilities
module Scope = Sg_caps_trie_scope
module Old_ops = Sg_capabilities_ops
module Q = QCheck2

let states pairs =
  Sgs_session_caps_states.make ~additional:(Sln_map.String.of_list pairs) Json_schema.Empty_obj.t

let convert caps = Oth.Assert.ok (Sg_caps_legacy_conversion.convert caps)

let commits ?states:s ?subgraph ?tenants () =
  Old_caps.make ~commit:(Some (Sgs_session_caps_commit.make ?states:s ?subgraph ?tenants ())) ()

let admin tenants = Old_caps.make ~admin:(Some (Sgs_session_caps_admin.make ~tenants ())) ()

let act ?(action = `Commit) ?(axis = `Modified) ~tenant ~state ~address () =
  New_caps.Act { action; axis; tenant; state; address }

(* What the stored record authorized, read by the functions production reads it with. *)
let legacy_authorizes old_caps = function
  | New_caps.Access_token_create ->
      CCOption.get_or ~default:false old_caps.Old_caps.access_token_create
  | New_caps.Access_token_refresh ->
      CCOption.get_or ~default:false old_caps.Old_caps.access_token_refresh
  | New_caps.Admin tenant -> Old_ops.grants_tenant old_caps `Admin tenant
  | New_caps.Users_manage tenant -> Old_ops.grants_tenant old_caps `Users_manage tenant
  | New_caps.Sudo user ->
      CCOption.map_or
        ~default:false
        (fun s -> Sg_caps_match.matches ~patterns:s.Sgs_session_caps_sudo.users user)
        old_caps.Old_caps.sudo
  | New_caps.Act { action; axis; tenant; state; address } ->
      Old_ops.grants_tenant old_caps `Admin tenant
      || CCOption.map_or
           ~default:false
           (fun grant ->
             let map =
               match axis with
               | `Modified -> grant.Old_ops.states
               | `Pulled_in -> grant.Old_ops.subgraph
             in
             Old_ops.tenants_permit grant.Old_ops.tenants tenant
             && CCOption.is_none (Old_ops.states_denial map ~state_id:state ~fq_address:address))
           (Old_ops.action_grant old_caps action)

let previews ?states:s ?subgraph ?tenants () =
  Old_caps.make ~preview:(Some (Sgs_session_caps_preview.make ?states:s ?subgraph ?tenants ())) ()

(* The new model's own vocabulary, to write down what a stored record is read as. *)
let scope = Sg_caps_trie_rule_text.scope

let reach ~tenants ~states ~addresses =
  Sg_caps_reach.make ~tenants:(scope tenants) ~states:(scope states) ~addresses:(scope addresses)

let both_actions reach = { New_caps.modified = reach; pulled_in = reach }

(* [converts stored expected] reads [stored] and checks it allows what [expected] allows. The
   judgment is [equivalent] rather than an equality of records: what is documented is the answers,
   not the shape they are stored in. *)
let check_conversion_equivalence stored expected =
  let actual = convert stored in
  Oth.Assert.true_
    ~fail_msg:
      (Format.asprintf "@[<v>read:     %a@,expected: %a@]" New_caps.pp actual New_caps.pp expected)
    (New_caps.equivalent actual expected)

let check_allows converted atom = Oth.Assert.true_ (New_caps.authorizes converted atom)
let check_refuses converted atom = Oth.Assert.not_true (New_caps.authorizes converted atom)

(* {1 One grant at a time} *)

let tenants_examples =
  Oth.test ~name:"tenants_examples" (fun _ ->
      let only_t1 = convert (commits ~tenants:(Some [ "t1" ]) ()) in
      check_allows only_t1 (act ~tenant:"t1" ~state:"s9" ~address:"anything" ());
      check_refuses only_t1 (act ~tenant:"t2" ~state:"s9" ~address:"anything" ());
      (* An absent list is every tenant, and a negation takes one back out. *)
      let every_tenant = convert (commits ()) in
      check_allows every_tenant (act ~tenant:"t2" ~state:"s9" ~address:"a" ());
      (* Let's take one out now. *)
      let all_but_t2 = convert (commits ~tenants:(Some [ "!t2" ]) ()) in
      check_refuses all_but_t2 (act ~tenant:"t2" ~state:"s9" ~address:"a" ());
      check_allows all_but_t2 (act ~tenant:"t1" ~state:"s9" ~address:"a" ());
      ())

let states_examples =
  Oth.test ~name:"states_examples" (fun _ ->
      let a_but_not_a_b =
        convert (commits ~states:(Some (states [ ("s1", Some [ "a.*"; "!a.b" ]) ])) ())
      in
      let addressed address = act ~tenant:"t1" ~state:"s1" ~address () in
      check_allows a_but_not_a_b (addressed "a.c");
      (* The refusal beats the pattern that allows it, wherever the two sit in the list. *)
      check_refuses a_but_not_a_b (addressed "a.b");
      (* A state the map does not name is out of scope. *)
      check_refuses a_but_not_a_b (act ~tenant:"t1" ~state:"s2" ~address:"a.c" ());
      (* [null] is every address of that state. *)
      let all_of_s1 = convert (commits ~states:(Some (states [ ("s1", None) ])) ()) in
      check_allows all_of_s1 (addressed "anything");
      (* [[]] is no addresses of that state *)
      let nothing_of_s1 = convert (commits ~states:(Some (states [ ("s1", Some []) ])) ()) in
      check_refuses nothing_of_s1 (addressed "a.c");
      ())

let states_star_key_examples =
  Oth.test ~name:"states_star_key_examples" (fun _ ->
      (* The ["*"] entry answers for the states no other key names, and a named key replaces it for
         itself alone rather than adding to it. *)
      let b_in_s1_a_elsewhere =
        convert (commits ~states:(Some (states [ ("*", Some [ "a.*" ]); ("s1", Some [ "b" ]) ])) ())
      in
      check_allows b_in_s1_a_elsewhere (act ~tenant:"t1" ~state:"s1" ~address:"b" ());
      check_refuses b_in_s1_a_elsewhere (act ~tenant:"t1" ~state:"s1" ~address:"a.c" ());
      check_allows b_in_s1_a_elsewhere (act ~tenant:"t2" ~state:"s2" ~address:"a.c" ());
      check_refuses b_in_s1_a_elsewhere (act ~tenant:"t2" ~state:"s2" ~address:"b" ());
      ())

let axes_examples =
  Oth.test ~name:"axes_examples" (fun _ ->
      (* [states] governs what the transaction modifies, [subgraph] what its bundle pulls in. *)
      let a_modified_b_pulled_in =
        convert
          (commits
             ~states:(Some (states [ ("s1", Some [ "a.*" ]) ]))
             ~subgraph:(Some (states [ ("s1", Some [ "b.*" ]) ]))
             ())
      in
      check_allows
        a_modified_b_pulled_in
        (act ~axis:`Modified ~tenant:"t1" ~state:"s1" ~address:"a.x" ());
      check_refuses
        a_modified_b_pulled_in
        (act ~axis:`Modified ~tenant:"t1" ~state:"s1" ~address:"b.x" ());
      check_allows
        a_modified_b_pulled_in
        (act ~axis:`Pulled_in ~tenant:"t1" ~state:"s1" ~address:"b.x" ());
      check_refuses
        a_modified_b_pulled_in
        (act ~axis:`Pulled_in ~tenant:"t1" ~state:"s1" ~address:"a.x" ());
      (* An absent axis reaches everything, and preview is read apart from commit. *)
      let commit_only = convert (commits ()) in
      check_allows commit_only (act ~axis:`Pulled_in ~tenant:"t1" ~state:"s1" ~address:"z" ());
      check_refuses commit_only (act ~action:`Preview ~tenant:"t1" ~state:"s1" ~address:"z" ());
      ())

let scopes_examples =
  Oth.test ~name:"scopes_examples" (fun _ ->
      let scoped =
        convert
          (Old_caps.make
             ~access_token_create:(Some true)
             ~admin:(Some (Sgs_session_caps_admin.make ~tenants:(Some [ "t1" ]) ()))
             ~users_manage:(Some (Sgs_session_caps_users_manage.make ()))
             ~sudo:(Some (Sgs_session_caps_sudo.make ~users:[ "u*"; "!ux" ]))
             ())
      in
      check_allows scoped New_caps.Access_token_create;
      check_refuses scoped New_caps.Access_token_refresh;
      check_allows scoped (New_caps.Admin "t1");
      check_refuses scoped (New_caps.Admin "t2");
      (* An absent [tenants] is every tenant. *)
      check_allows scoped (New_caps.Users_manage "t9");
      check_allows scoped (New_caps.Sudo "u1");
      check_refuses scoped (New_caps.Sudo "ux");
      (* An absent capability grants nothing, and so does one that names nothing. *)
      check_refuses (convert (Old_caps.make ())) (New_caps.Admin "t1");
      check_refuses (convert (admin (Some []))) (New_caps.Admin "t1");
      ())

(* {1 The records that are stored today}

   One example per shape the capability column actually holds, each written out in the new model.
   The state and tenant identifiers are uuids in the database; the strings below stand for them. *)

let sid = "state-1"
let other_sid = "state-2"
let tid = "tenant-1"

let stored_default_user_examples =
  Oth.test ~name:"stored_default_user_examples" (fun _ ->
      (* What almost every user carries: the two token capabilities, and preview and commit written
         as empty objects, which scope nothing and so reach every tenant, state and address. *)
      check_conversion_equivalence
        (Old_caps.make
           ~access_token_create:(Some true)
           ~access_token_refresh:(Some true)
           ~commit:(Some (Sgs_session_caps_commit.make ()))
           ~preview:(Some (Sgs_session_caps_preview.make ()))
           ())
        {
          New_caps.empty with
          New_caps.access_token_create = true;
          access_token_refresh = true;
          commit = both_actions Sg_caps_reach.everything;
          preview = both_actions Sg_caps_reach.everything;
        };
      (* An absent capability is the empty scope, and [false] is what an absent boolean was worth. *)
      check_conversion_equivalence (Old_caps.make ()) New_caps.empty;
      check_conversion_equivalence
        (Old_caps.make ~access_token_create:(Some false) ~access_token_refresh:(Some false) ())
        New_caps.empty;
      ())

let stored_administrator_examples =
  Oth.test ~name:"stored_administrator_examples" (fun _ ->
      (* An [admin] object with no allow-list is the installation-wide grant. *)
      check_conversion_equivalence (admin None) { New_caps.empty with New_caps.admin = Scope.full };
      (* Scoped to tenants, alone -- the shape a capability group rule grants. *)
      check_conversion_equivalence
        (admin (Some [ tid ]))
        { New_caps.empty with New_caps.admin = scope [ tid ] };
      (* Administering everything except one tenant: the list is all negations, so the old reading
         put an implicit ["*"] in front of it, which the new one writes down. *)
      check_conversion_equivalence
        (admin (Some [ "!" ^ tid ]))
        { New_caps.empty with New_caps.admin = scope [ "*"; "!" ^ tid ] };
      (* Managing the users of one tenant, which is not authority over its state. *)
      check_conversion_equivalence
        (Old_caps.make
           ~users_manage:(Some (Sgs_session_caps_users_manage.make ~tenants:(Some [ tid ]) ()))
           ())
        { New_caps.empty with New_caps.users_manage = scope [ tid ] };
      check_conversion_equivalence
        (Old_caps.make ~sudo:(Some (Sgs_session_caps_sudo.make ~users:[ "svc-*"; "!svc-root" ])) ())
        { New_caps.empty with New_caps.sudo = scope [ "svc-*"; "!svc-root" ] };
      ())

let stored_read_only_token_examples =
  Oth.test ~name:"stored_read_only_token_examples" (fun _ ->
      (* A token that may plan one state and nothing else. The axis it does not name -- what the
         bundle pulls in -- stays unrestricted, and commit is absent, so it reaches nothing. *)
      check_conversion_equivalence
        (previews ~states:(Some (states [ (sid, Some [ "*" ]) ])) ())
        {
          New_caps.empty with
          New_caps.preview =
            {
              New_caps.modified = reach ~tenants:[ "*" ] ~states:[ sid ] ~addresses:[ "*" ];
              pulled_in = Sg_caps_reach.everything;
            };
        };
      (* Scoped further, to the resources of that state whose address starts with a prefix. *)
      check_conversion_equivalence
        (previews ~states:(Some (states [ (sid, Some [ "terraform_data.allowed*" ]) ])) ())
        {
          New_caps.empty with
          New_caps.preview =
            {
              New_caps.modified =
                reach ~tenants:[ "*" ] ~states:[ sid ] ~addresses:[ "terraform_data.allowed*" ];
              pulled_in = Sg_caps_reach.everything;
            };
        };
      (* Everything of that state but one family of resources. *)
      check_conversion_equivalence
        (previews
           ~states:(Some (states [ (sid, Some [ "terraform_data.*"; "!terraform_data.denied*" ]) ]))
           ())
        {
          New_caps.empty with
          New_caps.preview =
            {
              New_caps.modified =
                reach
                  ~tenants:[ "*" ]
                  ~states:[ sid ]
                  ~addresses:[ "terraform_data.*"; "!terraform_data.denied*" ];
              pulled_in = Sg_caps_reach.everything;
            };
        };
      ())

let stored_plan_then_apply_token_examples =
  Oth.test ~name:"stored_plan_then_apply_token_examples" (fun _ ->
      (* Plan anywhere, apply only one state: the two actions are read apart. *)
      check_conversion_equivalence
        (Old_caps.make
           ~preview:(Some (Sgs_session_caps_preview.make ()))
           ~commit:
             (Some (Sgs_session_caps_commit.make ~states:(Some (states [ (sid, Some [ "*" ]) ])) ()))
           ())
        {
          New_caps.empty with
          New_caps.preview = both_actions Sg_caps_reach.everything;
          commit =
            {
              New_caps.modified = reach ~tenants:[ "*" ] ~states:[ sid ] ~addresses:[ "*" ];
              pulled_in = Sg_caps_reach.everything;
            };
        };
      (* Apply anywhere, as long as the bundle does not drag in a denied resource: the restriction
         is on the other axis, and the one the transaction writes stays open. *)
      check_conversion_equivalence
        (Old_caps.make
           ~commit:
             (Some
                (Sgs_session_caps_commit.make
                   ~subgraph:
                     (Some (states [ (sid, Some [ "terraform_data.*"; "!terraform_data.b" ]) ]))
                   ()))
           ())
        {
          New_caps.empty with
          New_caps.commit =
            {
              New_caps.modified = Sg_caps_reach.everything;
              pulled_in =
                reach
                  ~tenants:[ "*" ]
                  ~states:[ sid ]
                  ~addresses:[ "terraform_data.*"; "!terraform_data.b" ];
            };
        };
      ())

let stored_tenant_scoped_token_examples =
  Oth.test ~name:"stored_tenant_scoped_token_examples" (fun _ ->
      (* A token for one tenant, whatever its states hold. *)
      check_conversion_equivalence
        (previews ~tenants:(Some [ tid ]) ())
        {
          New_caps.empty with
          New_caps.preview =
            both_actions (reach ~tenants:[ tid ] ~states:[ "*" ] ~addresses:[ "*" ]);
        };
      (* A token for every tenant but one. *)
      check_conversion_equivalence
        (previews ~tenants:(Some [ "!" ^ tid ]) ())
        {
          New_caps.empty with
          New_caps.preview =
            both_actions (reach ~tenants:[ "*"; "!" ^ tid ] ~states:[ "*" ] ~addresses:[ "*" ]);
        };
      ())

let stored_state_map_examples =
  Oth.test ~name:"stored_state_map_examples" (fun _ ->
      (* Two states, each with its own resources: one map entry per state. *)
      check_conversion_equivalence
        (previews ~states:(Some (states [ (sid, Some [ "a.*" ]); (other_sid, Some [ "b.*" ]) ])) ())
        {
          New_caps.empty with
          New_caps.preview =
            {
              New_caps.modified =
                Sg_caps_reach.union
                  (reach ~tenants:[ "*" ] ~states:[ sid ] ~addresses:[ "a.*" ])
                  (reach ~tenants:[ "*" ] ~states:[ other_sid ] ~addresses:[ "b.*" ]);
              pulled_in = Sg_caps_reach.everything;
            };
        };
      (* The ["*"] entry answers for the states the map does not name, and a named state replaces
         it for itself rather than adding to it. *)
      check_conversion_equivalence
        (previews ~states:(Some (states [ ("*", Some [ "a.*" ]); (sid, Some [ "b" ]) ])) ())
        {
          New_caps.empty with
          New_caps.preview =
            {
              New_caps.modified =
                Sg_caps_reach.union
                  (reach ~tenants:[ "*" ] ~states:[ "*"; "!" ^ sid ] ~addresses:[ "a.*" ])
                  (reach ~tenants:[ "*" ] ~states:[ sid ] ~addresses:[ "b" ]);
              pulled_in = Sg_caps_reach.everything;
            };
        };
      (* A [null] value is every resource of that state. *)
      check_conversion_equivalence
        (previews ~states:(Some (states [ (sid, None) ])) ())
        {
          New_caps.empty with
          New_caps.preview =
            {
              New_caps.modified = reach ~tenants:[ "*" ] ~states:[ sid ] ~addresses:[ "*" ];
              pulled_in = Sg_caps_reach.everything;
            };
        };
      ())

let stored_denies_everything_examples =
  Oth.test ~name:"stored_denies_everything_examples" (fun _ ->
      (* Three ways of writing a preview that may modify nothing -- a refusal of every address, an
         empty list, and a map naming no state -- which read as the same value. They say nothing
         about the other axis, so what the bundle pulls in stays unrestricted. *)
      let modifies_nothing =
        {
          New_caps.empty with
          New_caps.preview =
            { New_caps.modified = Sg_caps_reach.empty; pulled_in = Sg_caps_reach.everything };
        }
      in
      check_conversion_equivalence
        (previews ~states:(Some (states [ ("*", Some [ "!*" ]) ])) ())
        modifies_nothing;
      check_conversion_equivalence
        (previews ~states:(Some (states [ (sid, Some []) ])) ())
        modifies_nothing;
      check_conversion_equivalence (previews ~states:(Some (states [])) ()) modifies_nothing;
      (* A tenant list that excludes every tenant closes both axes instead, which leaves the whole
         record allowing nothing at all. *)
      check_conversion_equivalence (previews ~tenants:(Some [ "!*" ]) ()) New_caps.empty;
      ())

(* {1 The decisions the conversion takes} *)

let admin_answers_for_the_action_examples =
  Oth.test ~name:"admin_answers_for_the_action_examples" (fun _ ->
      (* The stored record refused an action whose key was absent, even to an administrator: the
         presence check ran before the admin one. The converted set lets [admin] answer instead, so
         this atom is authorized where it was not. *)
      let stored = admin (Some [ "t1" ]) in
      Oth.Assert.true_ (CCOption.is_none (Old_ops.action_grant stored `Commit));
      let admin_of_t1 = convert stored in
      check_allows admin_of_t1 (act ~tenant:"t1" ~state:"s1" ~address:"a" ());
      check_refuses admin_of_t1 (act ~tenant:"t2" ~state:"s1" ~address:"a" ());
      (* An administrator of the tenant also passes every restriction the action grant writes. *)
      let admin_of_t1_committing_t2 =
        convert
          (Old_caps.make
             ~admin:(Some (Sgs_session_caps_admin.make ~tenants:(Some [ "t1" ]) ()))
             ~commit:(Some (Sgs_session_caps_commit.make ~tenants:(Some [ "t2" ]) ()))
             ())
      in
      check_allows admin_of_t1_committing_t2 (act ~tenant:"t1" ~state:"s1" ~address:"a" ());
      ())

let unreadable_patterns_examples =
  Oth.test ~name:"unreadable_patterns_examples" (fun _ ->
      let check_refused caps text =
        let (`Invalid_pattern_err rejected) =
          Oth.Assert.error (Sg_caps_legacy_conversion.convert caps)
        in
        Oth.Assert.Eq.string ~expected:text ~actual:rejected
      in
      (* A ['*'] that is not the last character. *)
      check_refused (commits ~tenants:(Some [ "a*b" ]) ()) "a*b";
      check_refused (commits ~states:(Some (states [ ("s1", Some [ "a*b" ]) ])) ()) "a*b";
      (* A state key is matched by equality, so only the key ["*"] itself is a pattern there. *)
      check_refused (commits ~states:(Some (states [ ("s*", Some [ "a" ]) ])) ()) "s*";
      (* A character below 32. *)
      check_refused (admin (Some [ "t\t1" ])) "t\t1";
      ())

(* {1 The same answers as the record it was read from} *)

module Gen = struct
  let text = Q.Gen.string_size ~gen:(Q.Gen.oneof_list [ 'a'; 'b'; '.' ]) (Q.Gen.int_bound 2)

  let pattern =
    Q.Gen.map
      (fun ((negated, text), star) ->
        (if negated then "!" else "") ^ text ^ if star then "*" else "")
      (Q.Gen.pair (Q.Gen.pair Q.Gen.bool text) Q.Gen.bool)

  let patterns = Q.Gen.list_size (Q.Gen.int_bound 3) pattern
  let patterns_opt = Q.Gen.option patterns
  let key = Q.Gen.oneof [ Q.Gen.pure "*"; text ]

  let states_opt =
    Q.Gen.option
      (Q.Gen.map
         states
         (Q.Gen.list_size (Q.Gen.int_bound 3) (Q.Gen.pair key (Q.Gen.option patterns))))

  let caps =
    let open Q.Gen in
    Q.Gen.option bool
    >>= fun access_token_create ->
    Q.Gen.option bool
    >>= fun access_token_refresh ->
    Q.Gen.option patterns_opt
    >>= fun admin ->
    Q.Gen.option patterns_opt
    >>= fun users_manage ->
    Q.Gen.option patterns
    >>= fun sudo ->
    Q.Gen.option (triple states_opt states_opt patterns_opt)
    >>= fun commit ->
    Q.Gen.option (triple states_opt states_opt patterns_opt)
    >|= fun preview ->
    Old_caps.make
      ~access_token_create
      ~access_token_refresh
      ~admin:(CCOption.map (fun tenants -> Sgs_session_caps_admin.make ~tenants ()) admin)
      ~users_manage:
        (CCOption.map (fun tenants -> Sgs_session_caps_users_manage.make ~tenants ()) users_manage)
      ~sudo:(CCOption.map (fun users -> Sgs_session_caps_sudo.make ~users) sudo)
      ~commit:
        (CCOption.map
           (fun (states, subgraph, tenants) ->
             Sgs_session_caps_commit.make ~states ~subgraph ~tenants ())
           commit)
      ~preview:
        (CCOption.map
           (fun (states, subgraph, tenants) ->
             Sgs_session_caps_preview.make ~states ~subgraph ~tenants ())
           preview)
      ()

  let atom =
    let open Q.Gen in
    let value = Q.Gen.map (fun t -> if CCString.is_empty t then "a" else t) text in
    Q.Gen.oneof
      [
        Q.Gen.pure New_caps.Access_token_create;
        Q.Gen.pure New_caps.Access_token_refresh;
        Q.Gen.map (fun t -> New_caps.Admin t) value;
        Q.Gen.map (fun t -> New_caps.Users_manage t) value;
        Q.Gen.map (fun u -> New_caps.Sudo u) value;
        (Q.Gen.oneof_list [ `Commit; `Preview ]
        >>= fun action ->
        Q.Gen.oneof_list [ `Modified; `Pulled_in ]
        >>= fun axis ->
        value
        >>= fun tenant ->
        value
        >>= fun state ->
        value >|= fun address -> New_caps.Act { action; axis; tenant; state; address });
      ]
end

let prop_same_answers =
  Oth.test ~name:"prop_same_answers" (fun _ ->
      Q.Test.check_exn
        ~rand:(Random.State.make_self_init ())
        (Q.Test.make
           ~count:2000
           ~name:"the converted set authorizes the atoms the record authorized"
           ~print:(Q.Print.pair Old_caps.show New_caps.show_atom)
           (Q.Gen.pair Gen.caps Gen.atom)
           (fun (caps, atom) ->
             match Sg_caps_legacy_conversion.convert caps with
             | Ok converted ->
                 CCBool.equal (New_caps.authorizes converted atom) (legacy_authorizes caps atom)
             | Error (`Invalid_pattern_err _) -> false)))

let test =
  Oth.parallel
    [
      tenants_examples;
      states_examples;
      states_star_key_examples;
      axes_examples;
      scopes_examples;
      stored_default_user_examples;
      stored_administrator_examples;
      stored_read_only_token_examples;
      stored_plan_then_apply_token_examples;
      stored_tenant_scoped_token_examples;
      stored_state_map_examples;
      stored_denies_everything_examples;
      admin_answers_for_the_action_examples;
      unreadable_patterns_examples;
      prop_same_answers;
    ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
