module Scope = Sg_caps_trie_scope

type actions = {
  modified : Sg_caps_reach.t;
  pulled_in : Sg_caps_reach.t;
}
[@@deriving show]

type t = {
  access_token_create : bool;
  access_token_refresh : bool;
  admin : Scope.t;
  users_manage : Scope.t;
  sudo : Scope.t;
  commit : actions;
  preview : actions;
}
[@@deriving show]

type atom =
  | Access_token_create
  | Access_token_refresh
  | Admin of string
  | Users_manage of string
  | Sudo of string
  | Act of {
      action : [ `Commit | `Preview ];
      axis : [ `Modified | `Pulled_in ];
      tenant : string;
      state : string;
      address : string;
    }
[@@deriving show]

let no_actions = { modified = Sg_caps_reach.empty; pulled_in = Sg_caps_reach.empty }

let empty =
  {
    access_token_create = false;
    access_token_refresh = false;
    admin = Scope.empty;
    users_manage = Scope.empty;
    sudo = Scope.empty;
    commit = no_actions;
    preview = no_actions;
  }

let all_actions = { modified = Sg_caps_reach.everything; pulled_in = Sg_caps_reach.everything }

let everything =
  {
    access_token_create = true;
    access_token_refresh = true;
    admin = Scope.full;
    users_manage = Scope.full;
    sudo = Scope.full;
    commit = all_actions;
    preview = all_actions;
  }

let grant caps = function
  | `Commit -> caps.commit
  | `Preview -> caps.preview

let along axis grant =
  match axis with
  | `Modified -> grant.modified
  | `Pulled_in -> grant.pulled_in

(* The preview and commit an [admin] grant implies: every state and every address of the tenants it
   names. *)
let implied_by_admin admin =
  Sg_caps_reach.make ~tenants:admin ~states:Scope.full ~addresses:Scope.full

let reaches caps action axis ~tenant ~state ~address =
  Sg_caps_reach.mem (along axis (grant caps action)) ~tenant ~state ~address

let authorizes caps = function
  | Access_token_create -> caps.access_token_create
  | Access_token_refresh -> caps.access_token_refresh
  | Admin tenant -> Scope.mem caps.admin tenant
  | Users_manage tenant -> Scope.mem caps.users_manage tenant
  | Sudo user -> Scope.mem caps.sudo user
  | Act { action; axis; tenant; state; address } ->
      Scope.mem caps.admin tenant || reaches caps action axis ~tenant ~state ~address

let map_actions f a b =
  { modified = f a.modified b.modified; pulled_in = f a.pulled_in b.pulled_in }

let union a b =
  {
    access_token_create = a.access_token_create || b.access_token_create;
    access_token_refresh = a.access_token_refresh || b.access_token_refresh;
    admin = Scope.union a.admin b.admin;
    users_manage = Scope.union a.users_manage b.users_manage;
    sudo = Scope.union a.sudo b.sudo;
    commit = map_actions Sg_caps_reach.union a.commit b.commit;
    preview = map_actions Sg_caps_reach.union a.preview b.preview;
  }

(* What an action grant reaches once the [admin] grant is read into it, which is what [authorizes]
   asks.  [inter] meets these, so that what one side allows through [admin] and the other through its
   grant survives. *)
let effective caps action =
  let implied = implied_by_admin caps.admin in
  let g = grant caps action in
  {
    modified = Sg_caps_reach.union g.modified implied;
    pulled_in = Sg_caps_reach.union g.pulled_in implied;
  }

(* [admin] is intersected on its own, and what it implies is taken back out of the action grant.
   If it was left in, taking a tenant out of the result's [admin] would no longer take away the preview and
   commit it implied. [authorizes] is unchanged, since every triple removed is one [admin] answers.
   See https://github.com/stategraph/mono/pull/2340#issuecomment-5716558886 and the corresponding test. *)
let inter a b =
  let admin = Scope.inter a.admin b.admin in
  let implied = implied_by_admin admin in
  let meet action =
    map_actions
      (fun x y -> Sg_caps_reach.diff (Sg_caps_reach.inter x y) implied)
      (effective a action)
      (effective b action)
  in
  {
    access_token_create = a.access_token_create && b.access_token_create;
    access_token_refresh = a.access_token_refresh && b.access_token_refresh;
    admin;
    users_manage = Scope.inter a.users_manage b.users_manage;
    sudo = Scope.inter a.sudo b.sudo;
    commit = meet `Commit;
    preview = meet `Preview;
  }

let entails a b =
  let allows_action action =
    let wider = effective a action in
    let narrower = effective b action in
    Sg_caps_reach.subset narrower.modified wider.modified
    && Sg_caps_reach.subset narrower.pulled_in wider.pulled_in
  in
  ((not b.access_token_create) || a.access_token_create)
  && ((not b.access_token_refresh) || a.access_token_refresh)
  && Scope.subset b.admin a.admin
  && Scope.subset b.users_manage a.users_manage
  && Scope.subset b.sudo a.sudo
  && allows_action `Commit
  && allows_action `Preview

let equivalent a b = entails a b && entails b a
