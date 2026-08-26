(** The result applicative this evaluator uses, in place of the one in {!Abbs_future_combinators}.

    The two differ in one thing. When both sides of a combination fail, [Abbs_future_combinators]
    keeps the error of the left side and throws the right one away. That loses a [`Rerun], which is
    not a failure but a request from a task that has committed something and needs the evaluation
    driven again: dropped, the transaction still commits the write, but the driver never re-drives,
    so the guard that was to answer differently on the second pass never runs. Here the two errors
    are ranked instead, and a [`Rerun] outranks everything.

    Nothing in this library may go back to {!Abbs_future_combinators.Result.all2} or
    {!Abbs_future_combinators.Infix_result_app}: a single such call site is enough to lose a
    [`Rerun] again. [Abbs_future_combinators] stays right for every other library, whose error types
    have no [`Rerun] in them. *)

(** [merge_err a b] is the error a combination of two failing sides reports.

    - Two [`Rerun]s join, deduplicated: an evaluation runs its tasks concurrently, so more than one
      can commit in a single pass, and a name that does not reach the driver is a name whose task
      writes again on the pass after this one.
    - Otherwise a [`Rerun] wins, a true error included.
    - Otherwise the left wins, which is what {!Abbs_future_combinators} does. *)
val merge_err : ([> `Rerun of string list ] as 'e) -> 'e -> 'e

(** Applicative for result types. Runs every future and applies the function, or reports
    {!merge_err} of the errors. A future evaluating to [Error _] does not abort the others.

    A chain groups to the left, so the left operand carries the merged error as the chain grows and
    a [`Rerun] in any position survives a chain of any length. That is why the [allN] below stop at
    six and the long check chains stay chains. *)
module Infix_result_app : sig
  type ('a, 'b) t = ('a, 'b) result Abb.Future.t

  val ( <$> ) : ('a -> 'b) -> ('a, ([> `Rerun of string list ] as 'e)) t -> ('b, 'e) t
  val ( <*> ) : ('a -> 'b, ([> `Rerun of string list ] as 'e)) t -> ('a, 'e) t -> ('b, 'e) t
end

(** Wait for the future, throw the [Ok] value away and keep the [Error]. There is one error here, so
    nothing is merged; it is re-exported only so that a call site never mixes
    [Abbs_future_combinators.Result] and this module. *)
val ignore : ('a, 'e) result Abb.Future.t -> (unit, 'e) result Abb.Future.t

val all2 :
  ('a, ([> `Rerun of string list ] as 'e)) result Abb.Future.t ->
  ('b, 'e) result Abb.Future.t ->
  ('a * 'b, 'e) result Abb.Future.t

val all3 :
  ('a, ([> `Rerun of string list ] as 'e)) result Abb.Future.t ->
  ('b, 'e) result Abb.Future.t ->
  ('c, 'e) result Abb.Future.t ->
  ('a * 'b * 'c, 'e) result Abb.Future.t

val all4 :
  ('a, ([> `Rerun of string list ] as 'e)) result Abb.Future.t ->
  ('b, 'e) result Abb.Future.t ->
  ('c, 'e) result Abb.Future.t ->
  ('d, 'e) result Abb.Future.t ->
  ('a * 'b * 'c * 'd, 'e) result Abb.Future.t

val all5 :
  ('a, ([> `Rerun of string list ] as 'e)) result Abb.Future.t ->
  ('b, 'e) result Abb.Future.t ->
  ('c, 'e) result Abb.Future.t ->
  ('d, 'e) result Abb.Future.t ->
  ('f, 'e) result Abb.Future.t ->
  ('a * 'b * 'c * 'd * 'f, 'e) result Abb.Future.t

val all6 :
  ('a, ([> `Rerun of string list ] as 'e)) result Abb.Future.t ->
  ('b, 'e) result Abb.Future.t ->
  ('c, 'e) result Abb.Future.t ->
  ('d, 'e) result Abb.Future.t ->
  ('f, 'e) result Abb.Future.t ->
  ('g, 'e) result Abb.Future.t ->
  ('a * 'b * 'c * 'd * 'f * 'g, 'e) result Abb.Future.t
