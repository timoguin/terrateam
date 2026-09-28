module Tag_query_sql = Terrat_sql_of_tag_query
module T = Tag_query_sql.Tag_map

let test_simple_pr =
  Oth.test ~name:"Simple pr" (fun _ ->
      let tq = "pr:123" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          match Tag_query_sql.of_ast ~tag_map:[ ("pr", (T.Bigint, "pull_number")) ] ast with
          | Ok t ->
              Oth.Assert.Eq.string
                ~expected:"pull_number = ($bigints)[1]"
                ~actual:(Tag_query_sql.sql t)
          | Error _ -> Oth.Assert.false_ "Simple pr: unexpected value")
      | Ok None -> Oth.Assert.false_ "Simple pr: unexpected value"
      | Error _ -> Oth.Assert.false_ "Simple pr: unexpected value")

let test_simple_user =
  Oth.test ~name:"Simple user" (fun _ ->
      let tq = "user:foo" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          match Tag_query_sql.of_ast ~tag_map:[ ("user", (T.String, "username")) ] ast with
          | Ok t ->
              Oth.Assert.Eq.string
                ~expected:"username = ($strings)[1]"
                ~actual:(Tag_query_sql.sql t)
          | Error _ -> Oth.Assert.false_ "Simple user: unexpected value")
      | Ok None -> Oth.Assert.false_ "Simple user: unexpected value"
      | Error _ -> Oth.Assert.false_ "Simple user: unexpected value")

let test_simple_dir =
  Oth.test ~name:"Simple dir" (fun _ ->
      let tq = "dir:foo" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          match
            Tag_query_sql.of_ast ~tag_map:[ ("dir", (T.Json_array "dir", "dirspaces")) ] ast
          with
          | Ok t ->
              Oth.Assert.Eq.string
                ~expected:"(dirspaces @> (($json)[1]::jsonb))"
                ~actual:(Tag_query_sql.sql t)
          | Error _ -> Oth.Assert.false_ "Simple dir: unexpected value")
      | Ok None -> Oth.Assert.false_ "Simple dir: unexpected value"
      | Error _ -> Oth.Assert.false_ "Simple dir: unexpected value")

let test_simple_repo =
  Oth.test ~name:"Simple repo" (fun _ ->
      let tq = "repo:foo" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          match Tag_query_sql.of_ast ~tag_map:[ ("repo", (T.String, "name")) ] ast with
          | Ok t ->
              Oth.Assert.Eq.string ~expected:"name = ($strings)[1]" ~actual:(Tag_query_sql.sql t)
          | Error _ -> Oth.Assert.false_ "Simple repo: unexpected value")
      | Ok None -> Oth.Assert.false_ "Simple repo: unexpected value"
      | Error _ -> Oth.Assert.false_ "Simple repo: unexpected value")

let test_simple_workspace =
  Oth.test ~name:"Simple workspace" (fun _ ->
      let tq = "workspace:foo" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          match
            Tag_query_sql.of_ast
              ~tag_map:[ ("workspace", (T.Json_array "workspace", "dirspaces")) ]
              ast
          with
          | Ok t ->
              Oth.Assert.Eq.string
                ~expected:"(dirspaces @> (($json)[1]::jsonb))"
                ~actual:(Tag_query_sql.sql t)
          | Error _ -> Oth.Assert.false_ "Simple workspace: unexpected value")
      | Ok None -> Oth.Assert.false_ "Simple workspace: unexpected value"
      | Error _ -> Oth.Assert.false_ "Simple workspace: unexpected value")

let test_simple_not =
  Oth.test ~name:"Simple not" (fun _ ->
      let tq = "not branch:foo" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          match Tag_query_sql.of_ast ~tag_map:[ ("branch", (T.String, "branch")) ] ast with
          | Ok t ->
              Oth.Assert.Eq.string
                ~expected:"not (branch = ($strings)[1])"
                ~actual:(Tag_query_sql.sql t)
          | Error _ -> Oth.Assert.false_ "Simple not: unexpected value")
      | Ok None -> Oth.Assert.false_ "Simple not: unexpected value"
      | Error _ -> Oth.Assert.false_ "Simple not: unexpected value")

let test_and =
  Oth.test ~name:"And" (fun _ ->
      let tq = "pr:123 and user:foo" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          match
            Tag_query_sql.of_ast
              ~tag_map:[ ("pr", (T.Bigint, "pull_number")); ("user", (T.String, "username")) ]
              ast
          with
          | Ok t ->
              Oth.Assert.Eq.string
                ~expected:"(pull_number = ($bigints)[1]) and (username = ($strings)[1])"
                ~actual:(Tag_query_sql.sql t)
          | Error _ -> Oth.Assert.false_ "And: unexpected value")
      | Ok None -> Oth.Assert.false_ "And: unexpected value"
      | Error _ -> Oth.Assert.false_ "And: unexpected value")

let test_or =
  Oth.test ~name:"Or" (fun _ ->
      let tq = "pr:123 or user:foo" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          match
            Tag_query_sql.of_ast
              ~tag_map:[ ("pr", (T.Bigint, "pull_number")); ("user", (T.String, "username")) ]
              ast
          with
          | Ok t ->
              Oth.Assert.Eq.string
                ~expected:"(pull_number = ($bigints)[1]) or (username = ($strings)[1])"
                ~actual:(Tag_query_sql.sql t)
          | Error _ -> Oth.Assert.false_ "Or: unexpected value")
      | Ok None -> Oth.Assert.false_ "Or: unexpected value"
      | Error _ -> Oth.Assert.false_ "Or: unexpected value")

(* RFD 2110, TQ-19.  An [outputs:] term has no meaning in SQL, so the
   conversion must refuse it with an error and not raise. *)
let test_outputs_not_supported =
  Oth.test ~tags:[ "rfd_2110" ] ~name:"TQ-19: outputs is an error, not an exception" (fun _ ->
      let tq = "foo.bar in outputs:app/db" in
      match Terrat_tag_query_ast.of_string tq with
      | Ok (Some ast) -> (
          match
            Tag_query_sql.of_ast ~tag_map:[ ("dir", (T.Json_array "dir", "dirspaces")) ] ast
          with
          | Ok _ -> Oth.Assert.false_ "TQ-19: expected an error"
          | Error _ -> ())
      | Ok None -> Oth.Assert.false_ "TQ-19: empty query"
      | Error err ->
          Oth.Assert.false_ ("TQ-19: does not parse: " ^ Terrat_tag_query_ast.show_err err))

let test =
  Oth.parallel
    [
      test_simple_pr;
      test_simple_user;
      test_simple_dir;
      test_simple_repo;
      test_simple_workspace;
      test_simple_not;
      test_and;
      test_or;
      test_outputs_not_supported;
    ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
