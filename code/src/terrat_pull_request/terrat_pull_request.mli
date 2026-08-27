module State : sig
  module Merged : sig
    type t = {
      merged_hash : string;
      merged_at : string;
    }
    [@@deriving yojson, show]
  end

  type t =
    | Open
    | Closed  (** The PR has been closed without merging *)
    | Merged of Merged.t  (** The PR has been closed by merging, we want the commit id *)
  [@@deriving yojson, show]
end

(** A service-agnostic definition of a pull request.

    The VCS's merge verdict is deliberately not here. A VCS calculates it asynchronously, so a
    caller that reads it must wait for it. Ask for it with [fetch_pull_request_mergeable], which
    only the code that needs the answer calls. *)
type ('id, 'diff, 'repo, 'ref) t [@@deriving yojson, show]

val make :
  base_branch_name:'ref ->
  base_ref:'ref ->
  branch_name:'ref ->
  branch_ref:'ref ->
  diff:'diff ->
  draft:bool ->
  id:'id ->
  provisional_merge_ref:'ref option ->
  repo:'repo ->
  state:State.t ->
  title:string option ->
  user:string option ->
  unit ->
  ('id, 'diff, 'repo, 'ref) t
[@@deriving show]

val base_branch_name : ('id, 'diff, 'repo, 'ref) t -> 'ref
val base_ref : ('id, 'diff, 'repo, 'ref) t -> 'ref
val branch_name : ('id, 'diff, 'repo, 'ref) t -> 'ref
val branch_ref : ('id, 'diff, 'repo, 'ref) t -> 'ref
val diff : ('id, 'diff, 'repo, 'ref) t -> 'diff
val id : ('id, 'diff, 'repo, 'ref) t -> 'id
val is_draft_pr : ('id, 'diff, 'repo, 'ref) t -> bool
val provisional_merge_ref : ('id, 'diff, 'repo, 'ref) t -> 'ref option
val repo : ('id, 'diff, 'repo, 'ref) t -> 'repo
val state : ('id, 'diff, 'repo, 'ref) t -> State.t
val title : ('id, 'diff, 'repo, 'ref) t -> string option
val user : ('id, 'diff, 'repo, 'ref) t -> string option
val set_diff : 'diff2 -> ('id, 'diff, 'repo, 'ref) t -> ('id, 'diff2, 'repo, 'ref) t
