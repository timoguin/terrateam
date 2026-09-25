module Exec : module type of Abb_bounded_suspendable_executor.Make (Abb) (CCString)

(** Builder defines all of the state, error messages, keys, and functionality to build. The usage
    is:

    1. Create a [t] using [make] with the tasks and the state.

    2. Use [eval] to execute a key and get its value or failure.

    In some cases, it may be desirable to evaluate a key using the initial state, because some
    evaluated keys needs to be invalidated. To do that, construct a new [t] with [reset] and then
    use [eval] *)
module Make (S : Terrat_vcs_provider2.S) : sig
  module Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)
  module Hmap : module type of Keys.Hmap

  type err = Keys.err [@@deriving show]

  module B : Buildsys.S with type 'v k = 'v Hmap.key and type 'a C.t = 'a Abb.Future.t

  module Bs :
    Buildsys.T
      with type 'a k = 'a B.k
       and type key_repr = string
       and type 'a c = 'a Abb.Future.t
       and type state = B.State.t
       and type queue = B.Queue.t

  val rebuilder : Bs.Rebuilder.t

  module State : sig
    type t = B.State.t

    val make :
      log_id:string ->
      store:Hmap.t ->
      config:S.Api.Config.t ->
      exec:Exec.t ->
      db:Pgsql_io.t ->
      tasks:Hmap.t ->
      unit ->
      B.State.t Abb.Future.t

    (** The state that [set_log_id], [set_tasks] and [set_path] give shares its store with [t]. A
        task of a build writes what it computes to that shared store. *)
    val set_log_id : string -> t -> t

    val config : t -> S.Api.Config.t
    val exec : t -> Exec.t
    val mark_dirty : t -> 'v Bs.k -> unit
    val orig_store : t -> Hmap.t

    (** [set_orig_store store t] is a state with a store of its own that starts from [store]. A
        nested eval must get a state from this function. *)
    val set_orig_store : Hmap.t -> t -> t

    val tasks : t -> Hmap.t
    val set_tasks : Hmap.t -> t -> t
    val set_path : Bs.key_repr list -> t -> t
    val root_path : t -> Bs.key_repr list

    (** If a store value exists in [s] add it to this store. Useful for constructing new stores when
        doing a nested eval call. *)
    val forward_store_value : 'v Bs.k -> t -> Hmap.t -> Hmap.t
  end

  val coerce_to_task : 'a B.k -> 'a Bs.Task.t B.k

  val run_db :
    B.State.t ->
    f:(Pgsql_io.t -> ('a, ([> `Closed ] as 'e)) result Abb.Future.t) ->
    ('a, ([> `Closed ] as 'e)) result Abb.Future.t

  val log_id : B.State.t -> string
  val mk_log_id : request_id:string -> Uuidm.t -> string

  (** [eval s k] builds [k] in the store of [s], and the caller reads the values that the build
      computed with [State.forward_store_value]. The build first resets the store of [s] to the
      store that [s] was made with, thus an eval does not start from what an earlier eval of [s]
      left. An eval on a state that shares its store with a running build resets the store of that
      build, thus a nested eval gets a state from [State.set_orig_store]. *)
  val eval : State.t -> 'v Bs.k -> 'v Bs.c
end
