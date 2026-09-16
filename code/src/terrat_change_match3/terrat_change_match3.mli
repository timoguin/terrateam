module Dependency_edge : sig
  (** One ordering between two dirspaces, and the configuration rule that put it there. [dependent]
      waits for [dependency]. [rule] is the name of the rule as the user wrote it: [depends_on],
      [plan_after] or [apply_after]. *)
  type t = {
    dependent : Terrat_dirspace.t;
    dependency : Terrat_dirspace.t;
    rule : string;
  }
  [@@deriving show, eq]
end

module Stack_boundary : sig
  (** A [depends_on] that reaches out of its stack: [dependent], in [dependent_stack], names
      [dependency], in [dependency_stack], and the two stacks have no stack in common. *)
  type t = {
    dependent : Terrat_dirspace.t;
    dependent_stack : string;
    dependency : Terrat_dirspace.t;
    dependency_stack : string;
  }
  [@@deriving show, eq]
end

type synthesize_config_err =
  [ `Depends_on_cycle_err of Dependency_edge.t list
  | `Depends_on_crosses_stack_err of Stack_boundary.t
  | `Workspace_in_multiple_stacks_err of Terrat_dirspace.t
  | `Workspace_matches_no_stacks_err of Terrat_dirspace.t
  | `Stack_not_found_err of string
  | `Stack_cycle_err of string list
  ]
[@@deriving show]

module Stack_config : sig
  type t = {
    name : string;
    paths : string list list;
        (** A list of all hierarchical paths that reach this stack, furthest away to closets. Each
            list always ends in [stack_name]. *)
    config : Terrat_base_repo_config_v1.Stacks.Stack.t;
  }
  [@@deriving show, eq, to_yojson]
end

module Dirspace_config : sig
  type t = {
    dirspace : Terrat_change.Dirspace.t;
    file_pattern_matcher : string -> bool;
    lock_branch_target : Terrat_base_repo_config_v1.Dirs.Dir.Branch_target.t;
    stack_config : Terrat_base_repo_config_v1.Stacks.Stack.t;
    stack_name : string;
    stack_paths : string list list;
    tags : Terrat_tag_set.t;
    when_modified : Terrat_base_repo_config_v1.When_modified.t;
  }
  [@@deriving show, to_yojson]
end

module Config : sig
  type t [@@deriving show, to_yojson]

  val dirspace_configs : t -> Dirspace_config.t Terrat_data.Dirspace_map.t
  val stack_topology : t -> string list Sln_map.String.t
  val stacks : t -> Stack_config.t Sln_map.String.t
end

val synthesize_config :
  index:Terrat_base_repo_config_v1.Index.t ->
  Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t ->
  (Config.t, [> synthesize_config_err ]) result

(** Given a config and a diff, find all dirspace configs that match the diff and return them in
    layers, in order of which can be executed. [force_matches] will insert specific matches into the
    output. This is useful if there are some matches which are required for reasons outside of the
    diff list *)
val match_diff_list :
  ?force_matches:Dirspace_config.t list ->
  Config.t ->
  Terrat_change.Diff.t list ->
  Dirspace_config.t list list

(** Put [dirspace_configs] into layers, in order of which can be executed. Pass the dirspaces of a
    run that remain to be applied and the first layer is what can run now.

    A dirspace outside [dirspace_configs] cannot delay anything, but it does not break the order
    between the dirspaces it sits between: a dependency that is already applied drops out and its
    dependent moves into the first layer, while a dirspace that never entered the run keeps carrying
    the order from the dirspace before it to the dirspace after it. *)
val layers_of : Config.t -> Dirspace_config.t list -> Dirspace_config.t list list

(** As {!layers_of}, but [apply_after] is an edge as well. Use it only to say how many rounds are
    left, never to choose what to run: [apply_after] holds an apply back without holding the plan
    back, so a dirspace it delays must still plan with the layer it belongs to. *)
val apply_layers_of : Config.t -> Dirspace_config.t list -> Dirspace_config.t list list

val of_dirspace : Config.t -> Terrat_dirspace.t -> Dirspace_config.t option
val merge_with_dedup : Dirspace_config.t list -> Dirspace_config.t list -> Dirspace_config.t list
val match_tag_query : tag_query:Terrat_tag_query.t -> Dirspace_config.t -> bool
