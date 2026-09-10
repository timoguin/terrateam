module Rs = Terrat_vcs_provider2.Resource_summary

let step ?(success = true) ~step_name payload_json =
  let module O = Terrat_api_components.Workflow_step_output in
  CCResult.get_or_failwith
  @@ O.of_yojson
       (`Assoc
          [
            ("ignore_errors", `Bool false);
            ("payload", payload_json);
            ( "scope",
              `Assoc
                [
                  ("type", `String "dirspace");
                  ("dir", `String "tf");
                  ("workspace", `String "default");
                ] );
            ("step", `String step_name);
            ("success", `Bool success);
          ])

let plan_step ?success () =
  step
    ?success
    ~step_name:"tf/plan"
    (`Assoc
       [
         ("has_changes", `Bool true);
         ( "resource_summary",
           `Assoc
             [ ("created", `Int 1); ("updated", `Int 0); ("replaced", `Int 0); ("deleted", `Int 0) ]
         );
       ])

let assert_summary = Oth.Assert.eq ~eq:Rs.equal ~pp:Rs.pp
let summary created updated replaced deleted = { Rs.created; updated; replaced; deleted }

(* [describe] without a summary returns the description unchanged; with one it
   appends the four counts, "-" for unreported ones, clipped at 140 chars. *)
let test_describe_no_summary =
  Oth.test ~name:"describe_no_summary" (fun _ ->
      Oth.Assert.Eq.string ~expected:"Completed" ~actual:(Rs.describe ~description:"Completed" ());
      ())

let test_describe_full_summary =
  Oth.test ~name:"describe_full_summary" (fun _ ->
      Oth.Assert.Eq.string
        ~expected:"Completed · 1 created, 0 updated, 0 replaced, 0 deleted"
        ~actual:
          (Rs.describe
             ~resource_summary:(summary (Some 1) (Some 0) (Some 0) (Some 0))
             ~description:"Completed"
             ());
      ())

let test_describe_partial_summary_dashes =
  Oth.test ~name:"describe_partial_summary_dashes" (fun _ ->
      Oth.Assert.Eq.string
        ~expected:"Failed · - created, - updated, 2 replaced, - deleted"
        ~actual:
          (Rs.describe ~resource_summary:(summary None None (Some 2) None) ~description:"Failed" ());
      ())

let test_describe_truncates_at_140 =
  Oth.test ~name:"describe_truncates_at_140" (fun _ ->
      let long = CCString.make 200 'x' in
      let text =
        Rs.describe ~resource_summary:(summary (Some 1) None None None) ~description:long ()
      in
      Oth.Assert.Eq.int ~expected:Rs.description_limit ~actual:(CCString.length text);
      ())

(* [of_steps] picks the plan step's summary and ignores other steps; an empty
   resource_summary object is treated as absent. *)
let test_of_steps_plan_step =
  Oth.test ~name:"of_steps_plan_step" (fun _ ->
      assert_summary
        (summary (Some 1) (Some 0) (Some 0) (Some 0))
        (Oth.Assert.some (Rs.of_steps [ plan_step () ]));
      ())

let test_of_steps_ignores_non_plan_steps =
  Oth.test ~name:"of_steps_ignores_non_plan_steps" (fun _ ->
      (* A summary on a non-plan step is ignored. *)
      Oth.Assert.none_pp
        ~pp:Rs.pp
        (Rs.of_steps
           [
             step
               ~step_name:"tf/init"
               (`Assoc [ ("resource_summary", `Assoc [ ("created", `Int 1) ]) ]);
           ]);
      (* A plan step's summary is still found after a summary-less init step. *)
      ignore (Oth.Assert.some (Rs.of_steps [ step ~step_name:"tf/init" (`Assoc []); plan_step () ]));
      ())

let test_of_steps_all_none_counts_treated_as_absent =
  Oth.test ~name:"of_steps_all_none_counts_treated_as_absent" (fun _ ->
      (* A resource_summary object that reports no count at all is treated as
         absent: the bare status word beats a row of dashes. *)
      let s =
        step
          ~step_name:"tf/plan"
          (`Assoc
             [
               ("has_changes", `Bool true);
               ( "resource_summary",
                 `Assoc
                   [
                     ("created", `Null); ("updated", `Null); ("replaced", `Null); ("deleted", `Null);
                   ] );
             ])
      in
      Oth.Assert.none_pp ~pp:Rs.pp (Rs.of_steps [ s ]);
      ())

let test_of_steps_empty_summary_absent =
  Oth.test ~name:"of_steps_empty_summary_absent" (fun _ ->
      let s = step ~step_name:"tf/plan" (`Assoc [ ("has_changes", `Bool true) ]) in
      Oth.Assert.none_pp ~pp:Rs.pp (Rs.of_steps [ s ]);
      ())

let test =
  Oth.serial
    [
      test_describe_no_summary;
      test_describe_full_summary;
      test_describe_partial_summary_dashes;
      test_describe_truncates_at_140;
      test_of_steps_plan_step;
      test_of_steps_ignores_non_plan_steps;
      test_of_steps_all_none_counts_treated_as_absent;
      test_of_steps_empty_summary_absent;
    ]

let () = Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
