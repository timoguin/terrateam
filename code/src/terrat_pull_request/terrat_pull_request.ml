module State = struct
  module Merged = struct
    type t = {
      merged_hash : string;
      merged_at : string;
    }
    [@@deriving yojson, show]
  end

  type t =
    | Open
    | Closed
    | Merged of Merged.t
  [@@deriving yojson, show]
end

type ('id, 'diff, 'repo, 'ref) t = {
  base_branch_name : 'ref;
  base_ref : 'ref;
  branch_name : 'ref;
  branch_ref : 'ref;
  diff : 'diff;
  draft : bool;
  id : 'id;
  provisional_merge_ref : 'ref option;
  repo : 'repo;
  state : State.t;
  title : string option;
  user : string option;
}
[@@deriving yojson, show]

let make
    ~base_branch_name
    ~base_ref
    ~branch_name
    ~branch_ref
    ~diff
    ~draft
    ~id
    ~provisional_merge_ref
    ~repo
    ~state
    ~title
    ~user
    () =
  {
    base_branch_name;
    base_ref;
    branch_name;
    branch_ref;
    diff;
    draft;
    id;
    provisional_merge_ref;
    repo;
    state;
    title;
    user;
  }

let base_branch_name t = t.base_branch_name
let base_ref t = t.base_ref
let branch_name t = t.branch_name
let branch_ref t = t.branch_ref
let diff t = t.diff
let id t = t.id
let is_draft_pr t = t.draft
let provisional_merge_ref t = t.provisional_merge_ref
let repo t = t.repo
let state t = t.state
let title t = t.title
let user t = t.user
let set_diff diff t = { t with diff }
