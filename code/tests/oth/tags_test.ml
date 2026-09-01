(* Self-hosted checks for [Oth.Tag.should_run_env], the tag-expression filter that
   [OTH_TAGS] / [OTH_EXCLUDE_TAGS] drive.

   As usual, checks go through [check] rather than [assert] (because the release profile compiles with
   -noassert)

   Deliberately using [failwith] rather than [Oth.Assert] either: this file tests the framework,
   so its own checks should not route through it. *)

let check msg b = if not b then failwith ("check failed: " ^ msg)
let t1_tags = [ "default"; "t1"; "grp_a"; "foo"; "foo_bar.ml" ]
let t2_tags = [ "default"; "t2"; "foo"; "foo_bar.ml" ]

let () =
  (* Unset (empty counts as unset): everything runs. *)
  Unix.putenv "OTH_TAGS" "";
  Unix.putenv "OTH_EXCLUDE_TAGS" "";
  check "unset runs t1" (Oth.Tag.should_run_env ~tags:t1_tags);
  check "unset runs t2" (Oth.Tag.should_run_env ~tags:t2_tags);
  (* Include filter selects only matching tag sets. *)
  Unix.putenv "OTH_TAGS" "grp_a";
  check "include selects t1" (Oth.Tag.should_run_env ~tags:t1_tags);
  check "include rejects t2" (not (Oth.Tag.should_run_env ~tags:t2_tags));
  (* Space separates alternatives: either tag selects its test. *)
  Unix.putenv "OTH_TAGS" "grp_a t2";
  check "alternative selects t1" (Oth.Tag.should_run_env ~tags:t1_tags);
  check "alternative selects t2" (Oth.Tag.should_run_env ~tags:t2_tags);
  (* Comma conjoins: every tag of the group must be present. *)
  Unix.putenv "OTH_TAGS" "grp_a,foo";
  check "conjunction selects t1" (Oth.Tag.should_run_env ~tags:t1_tags);
  check "conjunction rejects t2" (not (Oth.Tag.should_run_env ~tags:t2_tags));
  Unix.putenv "OTH_TAGS" "grp_a,t2";
  check "unsatisfied conjunction rejects t1" (not (Oth.Tag.should_run_env ~tags:t1_tags));
  check "unsatisfied conjunction rejects t2" (not (Oth.Tag.should_run_env ~tags:t2_tags));
  (* Alternatives of conjunctions: (grp_a AND nope) OR (t2 AND foo). *)
  Unix.putenv "OTH_TAGS" "grp_a,nope t2,foo";
  check "conjunction alternatives reject t1" (not (Oth.Tag.should_run_env ~tags:t1_tags));
  check "conjunction alternatives select t2" (Oth.Tag.should_run_env ~tags:t2_tags);
  (* Exclude beats include. *)
  Unix.putenv "OTH_TAGS" "grp_a";
  Unix.putenv "OTH_EXCLUDE_TAGS" "t1";
  check "exclude beats include" (not (Oth.Tag.should_run_env ~tags:t1_tags));
  (* A conjunctive exclusion only bites when all of its tags are present. *)
  Unix.putenv "OTH_TAGS" "";
  Unix.putenv "OTH_EXCLUDE_TAGS" "t1,nope";
  check "partial conjunctive exclusion does not bite" (Oth.Tag.should_run_env ~tags:t1_tags);
  Unix.putenv "OTH_EXCLUDE_TAGS" "t1,grp_a";
  check "full conjunctive exclusion bites t1" (not (Oth.Tag.should_run_env ~tags:t1_tags));
  check "conjunctive exclusion spares t2" (Oth.Tag.should_run_env ~tags:t2_tags)
