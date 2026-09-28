exception In_tag_error of string

(** The dirspace whose outputs an [outputs:] term reads. [Relative_outputs] is relative to the
    dirspace that declares the [depends_on], as [relative_dir:] is. *)
type outputs_target =
  | Outputs of string
  | Relative_outputs of string

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
  | In_outputs of {
      path : string;
      target : outputs_target;
    }  (** [foo.bar in outputs:app/db]: [path] is ["foo.bar"], [target] is [Outputs "app/db"]. *)

let outputs_prefix = "outputs:"
let relative_outputs_prefix = "relative_outputs:"

(* A prefix with nothing after it names no directory, thus it is not a target. *)
let outputs_target_of_string s =
  let after pre =
    CCOption.filter (fun dir -> not (CCString.is_empty dir)) (CCString.chop_prefix ~pre s)
  in
  match (after outputs_prefix, after relative_outputs_prefix) with
  | Some dir, _ -> Some (Outputs dir)
  | None, Some dir -> Some (Relative_outputs dir)
  | None, None -> None

let parse_in s = function
  | "dir" -> In_dir s
  | rhs -> (
      match outputs_target_of_string rhs with
      | Some target -> In_outputs { path = s; target }
      | None -> raise (In_tag_error rhs))
