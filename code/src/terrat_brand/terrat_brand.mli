type t =
  | Stategraph
  | Terrateam

val of_string : string -> t option
val to_string : t -> string
val brand : unit -> t
val to_terrateam : string -> string
val rewrite_template : string -> string
