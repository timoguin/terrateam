include
  Terrat_vcs_api.S
    with type Account.Id.t = int
     and type Config.vcs_config = Terrat_config.Github.t
     and type Client.native = Githubc2_abb.t
     and type User.Id.t = string
     and type Pull_request.Id.t = int
     and type Repo.Id.t = int

module Directory_entry : sig
  type kind =
    [ `Dir
    | `File
    | `Submodule
    | `Symlink
    ]
  [@@deriving show, eq]

  type t [@@deriving show, eq]

  val make : kind:kind -> name:string -> size:int -> unit -> t
  val kind : t -> kind
  val name : t -> string
  val size : t -> int
end

(** List the entries of one directory. A path that does not exist, or that holds a file, a symlink
    or a submodule, holds no entries and reads as [None].

    [`Listing_unavailable] means the contents endpoint refused to list the directory, which it does
    when the directory holds too many entries. It is not a failure of the call: read the names you
    want directly instead. *)
val fetch_directory :
  request_id:string ->
  Client.t ->
  Repo.t ->
  Ref.t ->
  string ->
  (Directory_entry.t list option, [> Terrat_vcs_api.call_err | `Listing_unavailable ]) result
  Abb.Future.t

(** The same as {!fetch_branch_sha}, but the answer is kept for a short time.

    Use this only where a slightly old SHA is acceptable, which is the repository configuration
    load: it reads the configuration of the default branch, and that configuration changes
    infrequently.

    Do not use it to find the ref that a run executes against. That answer must be current. Use
    {!fetch_branch_sha} there. *)
val fetch_branch_sha_cached :
  request_id:string ->
  Client.t ->
  Repo.t ->
  Ref.t ->
  (Ref.t option, [> Terrat_vcs_api.call_err ]) result Abb.Future.t
