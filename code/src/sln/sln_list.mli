module String : sig
  (** [CCList.mem ~eq:CCString.equal] *)
  val mem : string -> string list -> bool

  (** [CCList.sort CCString.compare] *)
  val sort : string list -> string list

  (** [CCList.equal CCString.equal] *)
  val equal : string list -> string list -> bool

  (** [CCList.uniq ~eq:CCString.equal] *)
  val uniq : string list -> string list

  (** [CCList.assoc_opt ~eq:CCString.equal] *)
  val assoc_opt : string -> (string * 'a) list -> 'a option
end

module Uuidm : sig
  (** [CCList.mem ~eq:Uuidm.equal] *)
  val mem : Uuidm.t -> Uuidm.t list -> bool
end
