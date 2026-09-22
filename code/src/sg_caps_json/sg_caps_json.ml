module Scope = Sg_caps_trie_scope
module Reach = Sg_caps_reach

type read_err =
  [ `Invalid_pattern_err of string
  | `Too_many_rules_err of string * int * int
  | `Malformed_err of string
  ]
[@@deriving show]

(* The most rules one scope may hold, and the most entries one level of a reach may. What reaches
   {!of_wire} from an endpoint is untrusted, is stored, is read on every request the holder makes,
   so we need to defend against malicious inputs. *)
let max_rules = 64
let max_entries = 64

(* Returns [l] if within bounds, [Error _] otherwise *)
let validate_bounds ~what ~limit l =
  let length = CCList.length l in
  if length <= limit then Ok l else Error (`Too_many_rules_err (what, length, limit))

let reach_to_wire reach =
  (* Note that Reach.to_rules's shortcircuit to emit [] is lifted here, making this function
     produce [] when Reach.to_rules does *)
  CCList.map
    (fun (tenant, states) ->
      {
        Sg_caps_wire_tenant_reach.tenant = Sg_caps_trie.Pattern.to_string tenant;
        states =
          CCList.map
            (fun (state, addresses) ->
              {
                Sg_caps_wire_state_reach.state = Sg_caps_trie.Pattern.to_string state;
                addresses = Scope.to_strings addresses;
              })
            states;
      })
    (Reach.to_rules reach)

let scope_of_wire ~what addresses =
  let open CCResult.Infix in
  validate_bounds ~what ~limit:max_rules addresses >>= fun addresses -> Scope.of_strings addresses

let reach_of_wire tenants =
  let open CCResult.Infix in
  validate_bounds ~what:"tenant rules" ~limit:max_entries tenants
  >>= fun tenants ->
  CCResult.map_l
    (fun { Sg_caps_wire_tenant_reach.tenant; states } ->
      Sg_caps_trie.Pattern.of_string tenant
      >>= fun tenant ->
      validate_bounds ~what:"state rules of one tenant" ~limit:max_entries states
      >>= fun states ->
      CCResult.map_l
        (fun { Sg_caps_wire_state_reach.state; addresses } ->
          Sg_caps_trie.Pattern.of_string state
          >>= fun state ->
          scope_of_wire ~what:"address rules of one state" addresses
          >|= fun addresses -> (state, addresses))
        states
      >|= fun states -> (tenant, states))
    tenants
  >|= Reach.of_rules

let actions_to_wire { Sg_caps.modified; pulled_in } =
  { Sg_caps_wire_actions.modified = reach_to_wire modified; pulled_in = reach_to_wire pulled_in }

let actions_of_wire { Sg_caps_wire_actions.modified; pulled_in } =
  let open CCResult.Infix in
  reach_of_wire modified
  >>= fun modified -> reach_of_wire pulled_in >|= fun pulled_in -> { Sg_caps.modified; pulled_in }

let to_wire caps =
  {
    Sg_caps_wire_capabilities.access_token_create = caps.Sg_caps.access_token_create;
    access_token_refresh = caps.Sg_caps.access_token_refresh;
    admin = Scope.to_strings caps.Sg_caps.admin;
    users_manage = Scope.to_strings caps.Sg_caps.users_manage;
    sudo = Scope.to_strings caps.Sg_caps.sudo;
    commit = actions_to_wire caps.Sg_caps.commit;
    preview = actions_to_wire caps.Sg_caps.preview;
  }

let of_wire wire =
  let open CCResult.Infix in
  scope_of_wire ~what:"admin rules" wire.Sg_caps_wire_capabilities.admin
  >>= fun admin ->
  scope_of_wire ~what:"users-manage rules" wire.Sg_caps_wire_capabilities.users_manage
  >>= fun users_manage ->
  scope_of_wire ~what:"sudo rules" wire.Sg_caps_wire_capabilities.sudo
  >>= fun sudo ->
  actions_of_wire wire.Sg_caps_wire_capabilities.commit
  >>= fun commit ->
  actions_of_wire wire.Sg_caps_wire_capabilities.preview
  >|= fun preview ->
  {
    Sg_caps.access_token_create = wire.Sg_caps_wire_capabilities.access_token_create;
    access_token_refresh = wire.Sg_caps_wire_capabilities.access_token_refresh;
    admin;
    users_manage;
    sudo;
    commit;
    preview;
  }

let to_json caps = Sg_caps_wire_capabilities.to_yojson (to_wire caps)

let of_json json =
  match Sg_caps_wire_capabilities.of_yojson json with
  | Error msg -> Error (`Malformed_err msg)
  | Ok wire -> of_wire wire

let read_err_to_string = function
  | `Invalid_pattern_err pattern ->
      Printf.sprintf
        "invalid capability pattern %S: a %S is only allowed as the last character, and every \
         character must be printable"
        pattern
        "*"
  | `Too_many_rules_err (what, length, limit) ->
      Printf.sprintf "too many %s: %d, at most %d" what length limit
  | `Malformed_err msg -> Printf.sprintf "not a capabilities object: %s" msg

type t = Sg_caps.t

let to_yojson = to_json
let of_yojson json = CCResult.map_err read_err_to_string (of_json json)
