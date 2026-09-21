(* The generators the properties of [Sg_caps] and of its codec draw from. *)
let text =
  QCheck2.Gen.string_size
    ~gen:(QCheck2.Gen.oneof_list [ 'a'; 'b'; 'c'; '.' ])
    (QCheck2.Gen.int_bound 2)

let pattern =
  QCheck2.Gen.map
    (fun (text, prefix) ->
      Oth.Assert.ok (Sg_caps_trie.Pattern.of_string (if prefix then text ^ "*" else text)))
    (QCheck2.Gen.pair text QCheck2.Gen.bool)

let scope =
  QCheck2.Gen.map
    Sg_caps_trie_scope.of_rules
    (QCheck2.Gen.list_size (QCheck2.Gen.int_bound 3) (QCheck2.Gen.pair pattern QCheck2.Gen.bool))

let reach =
  QCheck2.Gen.map
    (CCList.fold_left Sg_caps_reach.union Sg_caps_reach.empty)
    (QCheck2.Gen.list_size
       (QCheck2.Gen.int_bound 2)
       (QCheck2.Gen.map
          (fun (tenants, states, addresses) -> Sg_caps_reach.make ~tenants ~states ~addresses)
          (QCheck2.Gen.triple scope scope scope)))

let actions =
  QCheck2.Gen.map
    (fun (modified, pulled_in) -> { Sg_caps.modified; pulled_in })
    (QCheck2.Gen.pair reach reach)

let caps =
  let open QCheck2.Gen in
  bool
  >>= fun access_token_create ->
  bool
  >>= fun access_token_refresh ->
  scope
  >>= fun admin ->
  scope
  >>= fun users_manage ->
  scope
  >>= fun sudo ->
  actions
  >>= fun commit ->
  actions
  >|= fun preview ->
  { Sg_caps.access_token_create; access_token_refresh; admin; users_manage; sudo; commit; preview }
