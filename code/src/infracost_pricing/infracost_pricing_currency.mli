(** Rate that changes one US dollar into the given ISO 4217 code, as a decimal literal.

    {[
      rate "USD" = Some "1"
      rate "EUR" = Some "0.853994"
      rate "XYZ" = None
    ]} *)
val rate : string -> string option

(** Rate that changes one Chinese yuan into US dollars, as a decimal literal. A price that carries
    only a yuan amount gets its US dollar amount from this rate. *)
val cny_to_usd : string
