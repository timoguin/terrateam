(** The error answers, and their log lines, that endpoints share whatever they do. *)

(** JSON body of an [error-response] with the given [id] and [data]. *)
val error_response_body : id:string -> data:string -> string

(** Answer with an [error-response] body under [status]: [id] is the machine-readable error id the
    API conventions call for, [data] the human-readable detail. The neutral counterpart of the
    per-family [respond_error]s, for endpoints that do not belong to one of those families. *)
val respond_error :
  status:Cohttp.Code.status_code ->
  id:string ->
  data:string ->
  ('a, 'b) Brtl_ctx.t ->
  ('a, Brtl_rspnc.t) Brtl_ctx.t

(** Answer [500], by default with an empty body: an internal fault usually gives the caller nothing
    to act on, so the detail belongs in the logs. Log at the call site, then respond with this.

    [body] is for the endpoints that do have something to say — pass {!error_response_body} to send
    the [error-response] the API conventions describe, and make sure [api.json] declares it. *)
val respond_internal_error : ?body:string -> ('a, 'b) Brtl_ctx.t -> ('a, Brtl_rspnc.t) Brtl_ctx.t

(** Answer, and log, a database fault as [500]. The shared half of the access responders of
    {!Sgs_common}, and what an endpoint should call directly when it allows to keep the arms
    disjoints.

    The two halves of the union are distinct types with distinct printers, which is the whole reason
    to call this rather than match them apart at every endpoint. [body] is the [500] body, for an
    endpoint whose schema declares one; it defaults to empty, as {!respond_internal_error} does.

    [src] is the log source the fault is reported under, and it defaults to this module's [src].
    Prefer passing the endpoint's own [src]. *)
val respond_db_err :
  ?src:Logs.src ->
  ?body:string ->
  ('a, 'b) Brtl_ctx.t ->
  [< Pgsql_io.err | Pgsql_pool.err ] ->
  ('a, Brtl_rspnc.t) Brtl_ctx.t

(** Log a database fault with the line {!respond_db_err} writes, without answering: for an endpoint
    that answers the fault some other way, such as a redirect back to the console. [src] defaults to
    this module's [src]; prefer passing the endpoint's own. *)
val log_db_err : ?src:Logs.src -> ('a, 'b) Brtl_ctx.t -> [< Pgsql_io.err | Pgsql_pool.err ] -> unit

(** Answer, and log, a failure to read the session signing material: [500] either way, since neither
    is anything the caller can act on. Every endpoint that mints a session fails these same two
    ways, so sharing them is what keeps the status, the id and the log line from drifting apart.

    The two are logged apart because they are different operator problems: [`Key_not_found_err] is
    an [encryption_keys] with no [rsa] row, [`Bad_signing_key_err] a row that is not a usable RSA
    private key.

    Name the two constructors at the call site rather than matching
    [#Sgs_user_session.Session.fetch_key_err]: that union also subsumes [Pgsql_io.err], so the wider
    pattern would report a deadlock or a statement timeout as a missing key.

    [body] is the [500] body, for an endpoint whose schema declares one; it defaults to empty, as
    {!respond_internal_error} does. *)
val respond_signing_key_err :
  ?body:string ->
  ('a, 'b) Brtl_ctx.t ->
  [< `Key_not_found_err | `Bad_signing_key_err of string ] ->
  ('a, Brtl_rspnc.t) Brtl_ctx.t

(** Log a failure to read the session signing material with the lines {!respond_signing_key_err}
    writes, without answering: for an endpoint that answers it some other way, such as a redirect.
*)
val log_signing_key_err :
  ('a, 'b) Brtl_ctx.t -> [< `Key_not_found_err | `Bad_signing_key_err of string ] -> unit
