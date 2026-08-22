(** A file-descriptor handle with a per-handle [closed] flag.

    Shared by the fd-based schedulers ([abb_scheduler_luv], [abb_scheduler_select]) so the "fail
    fast once closed" and "close exactly once" logic is written once rather than repeated across
    every operation. [abb_scheduler_luv] wraps files in this too, not just sockets: libuv watches a
    descriptor by number, so an operation that reaches a number after its owner closed it is as
    wrong for a file as for a socket.

    The flag is per-handle, not per-fd-number: a fresh handle adopting a recycled fd starts
    un-closed, while the old handle stays closed -- so an operation on a stale handle fails instead
    of acting on a descriptor that now belongs to a different socket. *)

type t

(** [make fd] wraps [fd] in a fresh, open handle. *)
val make : Unix.file_descr -> t

(** [fd t] is the underlying descriptor. *)
val fd : t -> Unix.file_descr

(** [is_closed t] is [true] once [close_once] has been called on [t]. *)
val is_closed : t -> bool

(** [close_once t] marks [t] closed and returns [true] iff this call performed the transition (so a
    caller can run the underlying close exactly once). *)
val close_once : t -> bool
