module Authorization : sig
  type t =
    [ `Token of string
    | `Bearer of string
    ]
end

(** How a call can fail. [`Rate_limit_err] is the odd one out: [call] below never returns it. It is
    declared here so that every error type already built on [call_err] admits it without change, and
    it is produced by the retry wrappers that sit on top of [call] -- a wrapper that refuses to
    sleep longer than [call_timeout] has to say so somehow. *)
type call_err =
  [ `Conversion_err of string * string Openapi.Response.t
  | `Missing_response of string Openapi.Response.t
  | `Io_err of Abb_curl.Make(Abb).request_err
  | `Timeout
  | `Rate_limit_err
  ]
[@@deriving show]

type t

val create : ?user_agent:string -> ?base_url:Uri.t -> ?call_timeout:float -> Authorization.t -> t

(** The per-request timeout [call] enforces, if one was configured. Exposed so that a caller
    deciding how long to back off before retrying can refuse to wait longer than the call itself
    would have been allowed to run. *)
val call_timeout : t -> float option

val call : t -> 'a Openapi.Request.t -> ('a Openapi.Response.t, [> call_err ]) result Abb.Future.t

(** Iterate all of the pages in a paginated response and combine them. They are returned in the
    order they were received. *)
val collect_all :
  t ->
  [> `OK of 'a list ] Openapi.Request.t ->
  ('a list, [> call_err | `Error ]) result Abb.Future.t

val fold :
  t ->
  init:'a ->
  f:('a -> 'b Openapi.Response.t -> ('a, ([> call_err ] as 'e)) result Abb.Future.t) ->
  'b Openapi.Request.t ->
  ('a, 'e) result Abb.Future.t
