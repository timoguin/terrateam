(** Decides whether the outputs of a dirspace changed between two applies.

    A [depends_on] tag query can name a path into the outputs of a dependency, as in
    [db.host in outputs:app/database]. The dependent runs only if the value at that path changed
    since the most recent apply of the dependency in another pull request (the baseline). This
    module holds that comparison so that the tag query and the work set agree on what "changed"
    means. *)

(** How an engine lays out its outputs.

    [Tf_wrapped] is the layout of the Terraform family of engines: each output is an object
    [{"sensitive": ..., "type": ..., "value": ...}]. Only [value] is compared, so a change to
    [sensitive] or [type] alone is not a change, and a path below the output name selects inside
    [value].

    [Raw] is the layout of the custom engine: the JSON its [outputs] command prints, compared as is.
    Its keys are the output names, thus JSON that is not an object is the same as no outputs. *)
type shape =
  | Tf_wrapped
  | Raw

(** The outputs of one dirspace at the baseline apply and at the current apply. [None] means the
    apply recorded no outputs, which compares equal to [null]. *)
type t = {
  shape : shape;
  baseline : Yojson.Safe.t option;
  current : Yojson.Safe.t option;
}

(** [changed t ~path] is [true] if the value at [path] differs between [baseline] and [current].

    [path] is the dotted path of the tag query split on [.]; its first element is the output name.
    [None] asks whether any output changed, which is the meaning of a bare [outputs:dir]. It is
    [true] if the value of one output name differs, thus [{"a": null}] and [{}] are equal.

    A path segment selects a key of an object. A segment on a value that is not an object gives
    [null], thus [ips.0] does not select the first item of a list.

    Objects compare without regard to key order; lists compare in order. A path that does not exist
    evaluates to [null], and [null] has no special meaning: it is equal to [null] and differs from
    every other value. *)
val changed : t -> path:string list option -> bool
