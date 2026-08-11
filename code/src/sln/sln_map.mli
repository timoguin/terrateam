module String : sig
  include module type of CCMap.Make (CCString)

  val to_yojson : ('a -> 'b) -> 'a t -> [> `Assoc of (string * 'b) list ]

  val of_yojson :
    ('a -> ('b, string) result) -> [> `Assoc of (string * 'a) list ] -> ('b t, string) result

  val pp : (Format.formatter -> 'a -> unit) -> Format.formatter -> 'a t -> unit
  val show : (Format.formatter -> 'a -> unit) -> 'a t -> string
  val keys_set : 'a t -> Sln_set.String.t

  (** [override ~by m] is [m] with every binding of [by] taking precedence: a key bound in both
      takes its value from [by], a key bound in only one is kept. The named form of
      [union (fun _ _ by -> Some by) m by], which does not say which side wins at the call site. *)
  val override : by:'a t -> 'a t -> 'a t
end

module Uuidm : sig
  include module type of CCMap.Make (Uuidm)

  (** [by_uuidm_lists pairs] groups the [(key, value)] pairs by key, returning each key with the
      list of values added under it. *)
  val by_uuidm_lists : (Uuidm.t * 'a) list -> (Uuidm.t * 'a list) list
end
