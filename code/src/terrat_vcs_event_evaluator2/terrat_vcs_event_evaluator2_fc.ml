module Fc = Abbs_future_combinators

(* [`Rerun] outranks everything, a true error included.  It is not a failure: it
   says the task committed something and the evaluation has to be driven again.
   Ranking a true error above it would roll the transaction back, discard the
   write the rerun was protecting, and leave the work manifest that named it in
   [running] for ever.  Ranking it above a true error costs nothing the user
   sees: [Tasks_base.msg_of_err] is silent for [`Rerun], so this pass publishes
   nothing and the next pass gets the true error on its own and publishes it
   exactly once.

   Two reruns join.  [sort_uniq] is not cosmetic: the build system keeps a
   task's error against its key, so one task that two paths fetch in the same
   pass hands back the same name twice.

   Anything else keeps the left, which is what [Abbs_future_combinators] does
   and what the rest of this evaluator already relies on.  The wildcard is
   deliberate, and is not the case analysis this repository asks to be spelled
   out: the function is row-polymorphic in every constructor but [`Rerun], so
   there is no closed set of variants for the compiler to check. *)
let merge_err a b =
  match (a, b) with
  | `Rerun ids_a, `Rerun ids_b -> `Rerun (CCList.sort_uniq ~cmp:CCString.compare (ids_a @ ids_b))
  | (`Rerun _ as rerun), _ | _, (`Rerun _ as rerun) -> rerun
  | _ -> a

module Infix_result_app = struct
  type ('a, 'b) t = ('a, 'b) result Abb.Future.t

  (* Built on [Fc.all2] rather than hand rolled so the concurrency and the abort
     semantics stay exactly those of [Abb_fut.app]: both futures run to
     completion, and only an exception or an abort -- never an [Error] -- aborts
     the other.

     A chain groups to the left, so the left operand carries the merged error as
     the chain grows and a [`Rerun] in any position survives a chain of any
     length.  That is why this evaluator needs no [all9] or [all12] for the
     check chains in [Terrat_vcs_event_evaluator2_tasks_pr]. *)
  let ( <*> ) ft v =
    let open Abb.Future.Infix_monad in
    Fc.all2 ft v
    >>= function
    | Ok f, Ok v -> Abb.Future.return (Ok (f v))
    | Error err, Ok _ | Ok _, Error err -> Abb.Future.return (Error err)
    | Error err_a, Error err_b -> Abb.Future.return (Error (merge_err err_a err_b))

  let ( <$> ) f v = Abb.Future.return (Ok f) <*> v
end

(* No merge to make: there is one error to keep.  Re-exported so that a call
   site never has to mix [Fc.Result.] and this module. *)
let ignore fut = Fc.Result.ignore fut
let all2 a b = Infix_result_app.((fun a b -> (a, b)) <$> a <*> b)
let all3 a b c = Infix_result_app.((fun a b c -> (a, b, c)) <$> a <*> b <*> c)
let all4 a b c d = Infix_result_app.((fun a b c d -> (a, b, c, d)) <$> a <*> b <*> c <*> d)

let all5 a b c d e =
  Infix_result_app.((fun a b c d e -> (a, b, c, d, e)) <$> a <*> b <*> c <*> d <*> e)

let all6 a b c d e f =
  Infix_result_app.((fun a b c d e f -> (a, b, c, d, e, f)) <$> a <*> b <*> c <*> d <*> e <*> f)
