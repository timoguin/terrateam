type t =
  | Stategraph
  | Terrateam

let env_var = "TERRAT_BRAND"

let of_string = function
  | "stategraph" -> Some Stategraph
  | "terrateam" -> Some Terrateam
  | _ -> None

let to_string = function
  | Stategraph -> "stategraph"
  | Terrateam -> "terrateam"

let of_env =
  lazy
    (match Sys.getenv_opt env_var with
    | None -> Stategraph
    | Some s -> (
        match of_string (CCString.lowercase_ascii (CCString.trim s)) with
        | Some brand -> brand
        | None ->
            failwith
              (Printf.sprintf
                 "%s: unknown value %S, expected \"stategraph\" or \"terrateam\""
                 env_var
                 s)))

let brand () = Lazy.force of_env

let to_terrateam s =
  s
  |> CCString.replace ~sub:"stategraph.com" ~by:"terrateam.io"
  |> CCString.replace ~sub:"stategraph" ~by:"terrateam"
  |> CCString.replace ~sub:"Stategraph" ~by:"Terrateam"

let rewrite_template s =
  match brand () with
  | Stategraph -> s
  | Terrateam -> to_terrateam s
