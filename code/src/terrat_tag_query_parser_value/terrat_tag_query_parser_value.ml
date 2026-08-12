exception In_dir_tag_error of string

type t =
  | Tag of string
  | Or of t * t
  | And of t * t
      (** [And] is an explicit [and] between two expressions. [Implicit_and] is two expressions
          separated by nothing but whitespace, which means and binds exactly the same. They are kept
          apart because a query that matches nothing is usually a user that wrote a list of
          directories expecting them to be alternatives, and telling them so requires knowing they
          never typed an operator. *)
  | Implicit_and of t * t
  | Not of t
  | In_dir of string

let parse_in s = function
  | "dir" -> In_dir s
  | s -> raise (In_dir_tag_error s)
