module Tmpl = Terrat_vcs_github_comment_templates.Tmpl

let render tmpl kv =
  match Minijinja.render_template tmpl kv with
  | Ok body -> body
  | Error err -> failwith err

(* The same payload shape the provider builds for the [no matching dirspaces]
   messages, see [Terrat_vcs_provider2.Msg.no_matching_dirspaces_kv]. *)
let kv ~tag_query ~implicit_and ~suggestion =
  `Assoc
    [
      ("tag_query", `String tag_query);
      ("implicit_and", `Bool implicit_and);
      ( "suggestion",
        match suggestion with
        | Some suggestion -> `String suggestion
        | None -> `Null );
    ]

let test_apply_no_warning =
  Oth.test ~name:"Apply no warning" (fun _ ->
      let body =
        render
          Tmpl.apply_no_matching_dirspaces
          (kv ~tag_query:"dir:foo" ~implicit_and:false ~suggestion:None)
      in
      Oth.Assert.str_contains
        ~haystack:body
        ~needle:"There are no matching changes that are pending apply.";
      Oth.Assert.str_doesnt_contain ~haystack:body ~needle:"Did you mean")

let test_apply_warning_with_suggestion =
  Oth.test ~name:"Apply warning with suggestion" (fun _ ->
      let body =
        render
          Tmpl.apply_no_matching_dirspaces
          (kv
             ~tag_query:"dir:foo dir:bar"
             ~implicit_and:true
             ~suggestion:(Some "dir:foo or dir:bar"))
      in
      Oth.Assert.str_contains_all
        ~haystack:body
        ~needles:
          [
            "There are no matching changes that are pending apply.";
            "[!WARNING]";
            "Did you mean `or`?";
            "terrateam apply dir:foo or dir:bar";
          ])

let test_apply_warning_without_suggestion =
  Oth.test ~name:"Apply warning without suggestion" (fun _ ->
      let body =
        render
          Tmpl.apply_no_matching_dirspaces
          (kv ~tag_query:"dir:foo workspace:prod" ~implicit_and:true ~suggestion:None)
      in
      Oth.Assert.str_contains_all
        ~haystack:body
        ~needles:[ "Did you mean `or`?"; "`dir:foo workspace:prod`" ];
      (* Without a rewrite the only command offered is the unfiltered one. *)
      Oth.Assert.str_doesnt_contain ~haystack:body ~needle:"terrateam apply dir:")

let test_plan_no_warning =
  Oth.test ~name:"Plan no warning" (fun _ ->
      let body =
        render
          Tmpl.plan_no_matching_dirspaces
          (kv ~tag_query:"dir:foo" ~implicit_and:false ~suggestion:None)
      in
      Oth.Assert.str_contains ~haystack:body ~needle:"There are no matching changes to plan.";
      Oth.Assert.str_doesnt_contain ~haystack:body ~needle:"Did you mean")

let test_plan_warning_with_suggestion =
  Oth.test ~name:"Plan warning with suggestion" (fun _ ->
      let body =
        render
          Tmpl.plan_no_matching_dirspaces
          (kv
             ~tag_query:"dir:foo dir:bar"
             ~implicit_and:true
             ~suggestion:(Some "dir:foo or dir:bar"))
      in
      Oth.Assert.str_contains_all
        ~haystack:body
        ~needles:
          [
            "There are no matching changes to plan.";
            "Did you mean `or`?";
            "terrateam plan dir:foo or dir:bar";
          ])

let test_tag_query_dropped_dirspaces =
  Oth.test ~name:"Tag query dropped dirspaces" (fun _ ->
      let body =
        render
          Tmpl.tag_query_dropped_dirspaces
          (`Assoc
             [
               ("command", `String "terrateam apply");
               ("suggestion", `String "dir:a or dir:b or dir:c");
               ( "dirspaces",
                 `List
                   [
                     `Assoc [ ("dir", `String "b"); ("workspace", `String "default") ];
                     `Assoc [ ("dir", `String "c"); ("workspace", `String "default") ];
                   ] );
             ])
      in
      Oth.Assert.str_contains_all
        ~haystack:body
        ~needles:
          [
            "Some Directories Were Left Out";
            "| `b` | `default` |";
            "| `c` | `default` |";
            "terrateam apply dir:a or dir:b or dir:c";
          ])

let test_matches_in_later_layer =
  Oth.test ~name:"Matches in later layer" (fun _ ->
      let body =
        render
          Tmpl.matches_in_later_layer
          (`Assoc
             [
               ( "dirspaces",
                 `List
                   [
                     `Assoc [ ("dir", `String "tql/app"); ("workspace", `String "default") ];
                     `Assoc [ ("dir", `String "tql/web"); ("workspace", `String "prod") ];
                   ] );
             ])
      in
      Oth.Assert.str_contains_all
        ~haystack:body
        ~needles:
          [
            "Waiting On An Earlier Layer";
            "| `tql/app` | `default` |";
            "| `tql/web` | `prod` |";
            "terrateam plan";
          ])

let test =
  Oth.parallel
    [
      test_matches_in_later_layer;
      test_tag_query_dropped_dirspaces;
      test_apply_no_warning;
      test_apply_warning_with_suggestion;
      test_apply_warning_without_suggestion;
      test_plan_no_warning;
      test_plan_warning_with_suggestion;
    ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
