(** Regression test: [Abb.File.close]'s future must not resolve until the descriptor is closed. *)
module Make (_ : Abb_intf.S) : sig
  val test : Oth.Test.t
end
