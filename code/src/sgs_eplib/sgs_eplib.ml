let src = Logs.Src.create "eplib"

module Logs_lib = Logs
module Logs = (val Logs.src_log src : Logs.LOG)

let error_response_body ~id ~data =
  let module Err = Sgs_api_components_error_response in
  Yojson.Safe.to_string (Err.to_yojson { Err.id; data = Some data })

let respond_error ~status ~id ~data ctx =
  Brtl_ctx.set_response (Brtl_rspnc.create ~status (error_response_body ~id ~data)) ctx

(* A 500 defaults to an empty body: there is usually nothing the caller can act on, and whatever
   went wrong belongs in the logs rather than the response. [body] is for the endpoints that do have
   something to say -- pass {!error_response_body} to send the [error-response] the API conventions
   describe. Shared so the shape stays identical everywhere rather than being spelled out at each
   arm that reports an internal fault. *)
let respond_internal_error ?(body = "") ctx =
  Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error body) ctx

(* The half every access responder of [Sgs_common] shares.  Split out so an endpoint that checks more than one
   kind of access can name each refusal by its own constructor and answer the database faults once,
   instead of matching two [*_access_err] unions whose Pgsql halves overlap. *)
let log_db_err ?(src = src) ctx = function
  | #Pgsql_io.err as err ->
      Logs_lib.err ~src (fun m -> m "%s : DB_ERROR : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err)
  | #Pgsql_pool.err as err ->
      Logs_lib.err ~src (fun m -> m "%s : DB_ERROR : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err)

let respond_db_err ?src ?body ctx err =
  log_db_err ?src ctx err;
  respond_internal_error ?body ctx

(* Every endpoint that mints a session fails the same two ways when the signing material cannot be
   read, and has nothing of its own to say about either.  Shared so the status, the id and the log
   line stay identical at every one of them rather than drifting apart.  [body] carries the
   endpoint's own wording, as it does for [respond_db_err].

   The two constructors are logged apart because they are different operator problems: an
   [encryption_keys] with no [rsa] row against a row that is not a usable RSA private key. *)
let log_signing_key_err ctx = function
  | `Key_not_found_err ->
      Logs.err (fun m -> m "%s : DB_ERROR : No session signing key found" (Brtl_ctx.token ctx))
  | `Bad_signing_key_err msg ->
      Logs.err (fun m -> m "%s : DB_ERROR : Bad session signing key : %s" (Brtl_ctx.token ctx) msg)

let respond_signing_key_err ?body ctx err =
  log_signing_key_err ctx err;
  respond_internal_error ?body ctx
