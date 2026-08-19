(* Self-hosted checks for [Oth.Tag.should_run_env], the tag-expression filter that
   [OTH_TAGS] / [OTH_EXCLUDE_TAGS] drive. Uses [assert] directly: a failure
   crashes the process, which is what makes the dune test fail. *)

let t1_tags = [ "default"; "t1"; "grp_a"; "foo"; "foo_bar.ml" ]
let t2_tags = [ "default"; "t2"; "foo"; "foo_bar.ml" ]

let () =
  (* Unset (empty counts as unset): everything runs. *)
  Unix.putenv "OTH_TAGS" "";
  Unix.putenv "OTH_EXCLUDE_TAGS" "";
  assert (Oth.Tag.should_run_env ~tags:t1_tags);
  assert (Oth.Tag.should_run_env ~tags:t2_tags);
  (* Include filter selects only matching tag sets. *)
  Unix.putenv "OTH_TAGS" "grp_a";
  assert (Oth.Tag.should_run_env ~tags:t1_tags);
  assert (not (Oth.Tag.should_run_env ~tags:t2_tags));
  (* Space separates alternatives: either tag selects its test. *)
  Unix.putenv "OTH_TAGS" "grp_a t2";
  assert (Oth.Tag.should_run_env ~tags:t1_tags);
  assert (Oth.Tag.should_run_env ~tags:t2_tags);
  (* Comma conjoins: every tag of the group must be present. *)
  Unix.putenv "OTH_TAGS" "grp_a,foo";
  assert (Oth.Tag.should_run_env ~tags:t1_tags);
  assert (not (Oth.Tag.should_run_env ~tags:t2_tags));
  Unix.putenv "OTH_TAGS" "grp_a,t2";
  assert (not (Oth.Tag.should_run_env ~tags:t1_tags));
  assert (not (Oth.Tag.should_run_env ~tags:t2_tags));
  (* Alternatives of conjunctions: (grp_a AND nope) OR (t2 AND foo). *)
  Unix.putenv "OTH_TAGS" "grp_a,nope t2,foo";
  assert (not (Oth.Tag.should_run_env ~tags:t1_tags));
  assert (Oth.Tag.should_run_env ~tags:t2_tags);
  (* Exclude beats include. *)
  Unix.putenv "OTH_TAGS" "grp_a";
  Unix.putenv "OTH_EXCLUDE_TAGS" "t1";
  assert (not (Oth.Tag.should_run_env ~tags:t1_tags));
  (* A conjunctive exclusion only bites when all of its tags are present. *)
  Unix.putenv "OTH_TAGS" "";
  Unix.putenv "OTH_EXCLUDE_TAGS" "t1,nope";
  assert (Oth.Tag.should_run_env ~tags:t1_tags);
  Unix.putenv "OTH_EXCLUDE_TAGS" "t1,grp_a";
  assert (not (Oth.Tag.should_run_env ~tags:t1_tags));
  assert (Oth.Tag.should_run_env ~tags:t2_tags)
