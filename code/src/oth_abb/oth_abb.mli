(** The Abb-aware assertion vocabulary: everything in {!Oth.ASSERT}, plus the assertions that name
    an [Abb_intf] type.

    Extending {!Oth.ASSERT} rather than redeclaring it is the point — an async test reaches the
    whole vocabulary through one module path, [Oth_abb.Assert.*], and the shared part keeps a single
    implementation. Holding the [Abb_intf]-typed pieces here is what lets [oth] itself stay free of
    a dependency on [abb_intf]. *)
module type ASSERT = sig
  include Oth.ASSERT

  module Exit_code : sig
    (** Asserts that the process exited with a zero return code, otherwise fails the test. A
        signaled or stopped process also fails the test.

        [fail_msg] is APPENDED to the built-in reason rather than replacing it, unlike the
        [?fail_msg] on {!Oth.ASSERT.ok} and friends: the built-in text names the return code the
        process produced, which the caller cannot supply, while [fail_msg] says which command it was
        — for a test that shells out, usually the command's own output. Both are worth having. *)
    val zero : ?fail_msg:string -> Abb_intf.Process.Exit_code.t -> unit

    (** Asserts that the process exited, with a non-zero exit, otherwise fails the test. A signaled
        or stopped process also fails the test. [fail_msg] behaves as in {!zero}. *)
    val non_zero : ?fail_msg:string -> Abb_intf.Process.Exit_code.t -> unit
  end
end

module Assert : ASSERT

(** Set how many tests a run may execute at once, for a suite whose parallelism is a property of the
    environment it drives rather than of the operator's shell — [sg_ost_system_tests] sizes it from
    the number of repositories it was given.

    Call this BEFORE {!Make.run} / {!Make.run_phases}. The bounded executor is built before the
    suite's own [setup] runs, so a count set from [setup] arrives too late.

    What is set here WINS over [OTH_PARALLEL], because a suite that sets it owns a resource the
    operator cannot see and a larger [OTH_PARALLEL] would buy no concurrency, only a queue. Such a
    suite is expected to read [OTH_PARALLEL] itself and fold it into the value it sets. With no
    call, [OTH_PARALLEL] decides, and with neither the count is 1. *)
val set_default_slots : int -> unit

module Make (Abb : Abb_intf.S) : sig
  include Oth.S with type 'a m = 'a Abb.Future.t

  (** Re-export of the toplevel {!Assert}. Nothing in it depends on [Abb], but a call site that
      writes [module Oth_abb = Oth_abb.Make (Abb)] shadows the library name and so cannot reach the
      toplevel module; re-exporting means both spellings resolve. *)
  module Assert : ASSERT

  (** Re-export of the toplevel {!set_default_slots}, for the same reason {!Assert} is re-exported:
      a call site that writes [module Oth_abb = Oth_abb.Make (Abb)] cannot reach the toplevel
      module. *)
  val set_default_slots : int -> unit

  (** No-op identity. Kept so migrated call sites need not be edited. *)
  val to_sync_test : Test.t -> Test.t
end
