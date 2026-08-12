module Parse_errors = struct
  (* These errors are named after their state in the .messages file *)

  let rparen =
    "This query could not be parsed.  This could be for a few reasons:\n\
     - There are too many closing right parantheses.\n\
     - There is an `and` or `or` that is missing both sides to its expression.  If you have a tag \
     named `or`, `and`, or `not`, then wrap it in quotes to treat it like a tag name rather than \
     an operator, for example `\"and\"`."

  let not_rparen =
    "Have read a `not` but expected a tag or an opening parantheses.  To treat `not` as a tag, \
     wrap it in quotes: `\"not\"`."

  let lparen_rparen = "Parentheses must contain an expression, `()` is not allowed."
  let lparen_tag_eof = "Missing closing parentheses."

  let tag_or_rparen =
    "An `or` expression with a closing parenthesis where a tag was expected.  In order to treat \
     the `or` as a tag, wrap it in quotes, for example `\"or\"`."

  let tag_and_rparen =
    "An `and` expression with a closing parenthesis where a tag was expected.  In order to treat \
     the `and` as a tag, wrap it in quotes, for example `\"and\"`."

  let tag_rparen = "Missing opening parentheses."
  let not_lparen_tag_eof = "Missing closing parentheses."

  (* Named after the error the lexer throws *)
  let premature_end_of_string s = Printf.sprintf "Premature end of string in `%s`." s

  let in_dir_tag_error s =
    Printf.sprintf "The `in` operator only accepts `dir` on the right hand side, got `%s`." s
end

let print_of_string = function
  | Ok t -> Printf.printf "Ok (%s)\n%!" (Terrat_tag_query.show t)
  | Error err -> Printf.printf "Error (%s)\n%!" (Terrat_tag_query_ast.show_err err)

let of_string_exn s =
  match Terrat_tag_query.of_string s with
  | Ok q -> q
  | Error err -> failwith (Terrat_tag_query_ast.show_err err)

let test_simple_match =
  Oth.test ~name:"Simple match" (fun _ ->
      let query = of_string_exn "a" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_simple_no_match =
  Oth.test ~name:"Simple no match" (fun _ ->
      let query = of_string_exn "d" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "not (Terrat_tag_query.match_ ~ctx ~tag_set query)"
        (not (Terrat_tag_query.match_ ~ctx ~tag_set query)))

let test_simple_and =
  Oth.test ~name:"Simple and" (fun _ ->
      let query = of_string_exn "a b" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_dir_glob_at_start =
  Oth.test ~name:"Simple Dir glob at start" (fun _ ->
      let query = of_string_exn "foo in dir" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_dir_glob_inner =
  Oth.test ~name:"Simple Dir glob inner" (fun _ ->
      let query = of_string_exn "bar in dir" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_dir_glob_at_end =
  Oth.test ~name:"Simple Dir glob at end" (fun _ ->
      let query = of_string_exn "zoom in dir" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_dir_glob_cross_dirs =
  Oth.test ~name:"Simple Dir glob cross dirs" (fun _ ->
      let query = of_string_exn "bar/baz in dir" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_dir_glob_not_match_partial =
  Oth.test ~name:"Simple Dir glob does not match partial" (fun _ ->
      let query = of_string_exn "az in dir" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "not (Terrat_tag_query.match_ ~ctx ~tag_set query)"
        (not (Terrat_tag_query.match_ ~ctx ~tag_set query)))

let test_dir_glob_no_match_with_slashes =
  Oth.test ~name:"Simple Dir glob does not match with slashes" (fun _ ->
      let query = of_string_exn "/bar/ in dir" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "not (Terrat_tag_query.match_ ~ctx ~tag_set query)"
        (not (Terrat_tag_query.match_ ~ctx ~tag_set query)))

let test_bad_glob =
  Oth.test ~name:"Bad glob" (fun _ ->
      let query = of_string_exn "ba*r in dir" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "not (Terrat_tag_query.match_ ~ctx ~tag_set query)"
        (not (Terrat_tag_query.match_ ~ctx ~tag_set query)))

let test_query_with_extra_spaces =
  Oth.test ~name:"Query with extra spaces" (fun _ ->
      let query = of_string_exn "a                  b" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_complex_query_match =
  Oth.test ~name:"Complex query match" (fun _ ->
      let query = of_string_exn "a                  b   bar/baz in dir" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_complex_query_no_match =
  Oth.test ~name:"Complex query no match" (fun _ ->
      let query = of_string_exn "a                  b   bar/baz1 in dir" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "not (Terrat_tag_query.match_ ~ctx ~tag_set query)"
        (not (Terrat_tag_query.match_ ~ctx ~tag_set query)))

let test_empty_query =
  Oth.test ~name:"Empty query" (fun _ ->
      let query = of_string_exn "" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_and =
  Oth.test ~name:"And" (fun _ ->
      let query = of_string_exn "a and b" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_and_precedence_1 =
  Oth.test ~name:"And precedence 1" (fun _ ->
      let query = of_string_exn "a and d or c" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_and_precedence_2 =
  Oth.test ~name:"And precedence 2" (fun _ ->
      let query = of_string_exn "a and b or d" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_and_precedence_3 =
  Oth.test ~name:"And precedence 3" (fun _ ->
      let query = of_string_exn "a and e or d" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "not (Terrat_tag_query.match_ ~ctx ~tag_set query)"
        (not (Terrat_tag_query.match_ ~ctx ~tag_set query)))

let test_or_1 =
  Oth.test ~name:"Or 1" (fun _ ->
      let query = of_string_exn "a or b" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_or_2 =
  Oth.test ~name:"Or 2" (fun _ ->
      let query = of_string_exn "a or b" in
      let tag_set = Terrat_tag_set.of_list [ "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_parens_1 =
  Oth.test ~name:"Parens 1" (fun _ ->
      let query = of_string_exn "(a b)" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_parens_with_and =
  Oth.test ~name:"Parens with and" (fun _ ->
      let query = of_string_exn "(a and b)" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_parens_with_or =
  Oth.test ~name:"Parens with or" (fun _ ->
      let query = of_string_exn "(a or b)" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_parens_2 =
  Oth.test ~name:"Parens 2" (fun _ ->
      let query = of_string_exn "(a or b) and (c or d)" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_parens_no_match_1 =
  Oth.test ~name:"Parens no match 1" (fun _ ->
      let query = of_string_exn "(a or b) and (c or d)" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "not (Terrat_tag_query.match_ ~ctx ~tag_set query)"
        (not (Terrat_tag_query.match_ ~ctx ~tag_set query)))

let test_not_1 =
  Oth.test ~name:"Not 1" (fun _ ->
      let query = of_string_exn "not a" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "not (Terrat_tag_query.match_ ~ctx ~tag_set query)"
        (not (Terrat_tag_query.match_ ~ctx ~tag_set query)))

let test_not_2 =
  Oth.test ~name:"Not 2" (fun _ ->
      let query = of_string_exn "not c" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_not_3 =
  Oth.test ~name:"Not 3" (fun _ ->
      let query = of_string_exn "not c and a" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_not_4 =
  Oth.test ~name:"Not 4" (fun _ ->
      let query = of_string_exn "not (c and a)" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_not_5 =
  Oth.test ~name:"Not 5" (fun _ ->
      let query = of_string_exn "not (a and b)" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "not (Terrat_tag_query.match_ ~ctx ~tag_set query)"
        (not (Terrat_tag_query.match_ ~ctx ~tag_set query)))

let test_not_6 =
  Oth.test ~name:"Not 6" (fun _ ->
      let query = of_string_exn "not a d" in
      let tag_set = Terrat_tag_set.of_list [ "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "not (Terrat_tag_query.match_ ~ctx ~tag_set query)"
        (not (Terrat_tag_query.match_ ~ctx ~tag_set query)))

let test_complex_1 =
  Oth.test ~name:"Complex 1" (fun _ ->
      let query = of_string_exn "bar in dir and zoom in dir" in
      let tag_set = Terrat_tag_set.of_list [ "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_complex_2 =
  Oth.test ~name:"Complex 2" (fun _ ->
      let query = of_string_exn "bar in dir and zoom in dir and not (foo in dir)" in
      let tag_set = Terrat_tag_set.of_list [ "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "not (Terrat_tag_query.match_ ~ctx ~tag_set query)"
        (not (Terrat_tag_query.match_ ~ctx ~tag_set query)))

let test_to_string =
  Oth.test ~name:"To string" (fun _ ->
      let s = "a                  b   bar/baz in dir" in
      let query = of_string_exn s in
      Oth.Assert.true_ "Terrat_tag_query.to_string query = s" (Terrat_tag_query.to_string query = s))

let test_parse_failure_1 =
  Oth.test ~name:"Parse failure 1" (fun _ ->
      let query = "()" in
      Oth.Assert.true_
        "Error (`Tag_query_error (query, Parse_errors.lparen_rparen)) = Terrat_tag_query.of_string \
         query"
        (Error (`Tag_query_error (query, Parse_errors.lparen_rparen))
        = Terrat_tag_query.of_string query))

let test_parse_failure_2 =
  Oth.test ~name:"Parse failure 2" (fun _ ->
      let query = ")" in
      Oth.Assert.true_
        "Error (`Tag_query_error (query, Parse_errors.rparen)) = Terrat_tag_query.of_string query"
        (Error (`Tag_query_error (query, Parse_errors.rparen)) = Terrat_tag_query.of_string query))

let test_parse_failure_3 =
  Oth.test ~name:"Parse failure 3" (fun _ ->
      let query = "(not)" in
      Oth.Assert.true_
        "Error (`Tag_query_error (query, Parse_errors.not_rparen)) = Terrat_tag_query.of_string \
         query"
        (Error (`Tag_query_error (query, Parse_errors.not_rparen))
        = Terrat_tag_query.of_string query))

let test_parse_failure_4 =
  Oth.test ~name:"Parse failure 4" (fun _ ->
      let query = "\"foo" in
      Oth.Assert.true_
        "Error (`Tag_query_error (query, Parse_errors.premature_end_of_string \"foo\")) = \
         Terrat_tag_query.of_string query"
        (Error (`Tag_query_error (query, Parse_errors.premature_end_of_string "foo"))
        = Terrat_tag_query.of_string query))

let test_parse_failure_5 =
  Oth.test ~name:"Parse failure 5" (fun _ ->
      let query = "'foo" in
      Oth.Assert.true_
        "Error (`Tag_query_error (query, Parse_errors.premature_end_of_string \"foo\")) = \
         Terrat_tag_query.of_string query"
        (Error (`Tag_query_error (query, Parse_errors.premature_end_of_string "foo"))
        = Terrat_tag_query.of_string query))

let test_parse_failure_6 =
  Oth.test ~name:"Parse failure 6" (fun _ ->
      let query = "and foo" in
      Oth.Assert.true_
        "Error (`Tag_query_error (query, Parse_errors.rparen)) = Terrat_tag_query.of_string query"
        (Error (`Tag_query_error (query, Parse_errors.rparen)) = Terrat_tag_query.of_string query))

let test_parse_failure_7 =
  Oth.test ~name:"Parse failure 7" (fun _ ->
      let query = "not)" in
      Oth.Assert.true_
        "Error (`Tag_query_error (query, Parse_errors.not_rparen)) = Terrat_tag_query.of_string \
         query"
        (Error (`Tag_query_error (query, Parse_errors.not_rparen))
        = Terrat_tag_query.of_string query))

let test_parse_failure_8 =
  Oth.test ~name:"Parse failure 8" (fun _ ->
      let query = "not ()" in
      Oth.Assert.true_
        "Error (`Tag_query_error (query, Parse_errors.lparen_rparen)) = Terrat_tag_query.of_string \
         query"
        (Error (`Tag_query_error (query, Parse_errors.lparen_rparen))
        = Terrat_tag_query.of_string query))

let test_parse_failure_9 =
  Oth.test ~name:"Parse failure 9" (fun _ ->
      let query = "(foo" in
      Oth.Assert.true_
        "Error (`Tag_query_error (query, Parse_errors.lparen_tag_eof)) = \
         Terrat_tag_query.of_string query"
        (Error (`Tag_query_error (query, Parse_errors.lparen_tag_eof))
        = Terrat_tag_query.of_string query))

let test_parse_failure_10 =
  Oth.test ~name:"Parse failure 10" (fun _ ->
      let query = "(foo or)" in
      Oth.Assert.true_
        "Error (`Tag_query_error (query, Parse_errors.tag_or_rparen)) = Terrat_tag_query.of_string \
         query"
        (Error (`Tag_query_error (query, Parse_errors.tag_or_rparen))
        = Terrat_tag_query.of_string query))

let test_parse_failure_11 =
  Oth.test ~name:"Parse failure 11" (fun _ ->
      let query = "(foo and)" in
      Oth.Assert.true_
        "Error (`Tag_query_error (query, Parse_errors.tag_and_rparen)) = \
         Terrat_tag_query.of_string query"
        (Error (`Tag_query_error (query, Parse_errors.tag_and_rparen))
        = Terrat_tag_query.of_string query))

let test_parse_failure_12 =
  Oth.test ~name:"Parse failure 12" (fun _ ->
      let query = "foo and)" in
      Oth.Assert.true_
        "Error (`Tag_query_error (query, Parse_errors.tag_and_rparen)) = \
         Terrat_tag_query.of_string query"
        (Error (`Tag_query_error (query, Parse_errors.tag_and_rparen))
        = Terrat_tag_query.of_string query))

let test_parse_failure_13 =
  Oth.test ~name:"Parse failure 13" (fun _ ->
      let query = "foo)" in
      Oth.Assert.true_
        "Error (`Tag_query_error (query, Parse_errors.tag_rparen)) = Terrat_tag_query.of_string \
         query"
        (Error (`Tag_query_error (query, Parse_errors.tag_rparen))
        = Terrat_tag_query.of_string query))

let test_parse_failure_14 =
  Oth.test ~name:"Parse failure 14" (fun _ ->
      let query = "not (foo" in
      Oth.Assert.true_
        "Error (`Tag_query_error (query, Parse_errors.not_lparen_tag_eof)) = \
         Terrat_tag_query.of_string query"
        (Error (`Tag_query_error (query, Parse_errors.not_lparen_tag_eof))
        = Terrat_tag_query.of_string query))

let test_parse_failure_15 =
  Oth.test ~name:"Parse failure 15" (fun _ ->
      let query = "foo in bar" in
      print_of_string (Terrat_tag_query.of_string query);
      Oth.Assert.true_
        "Error (`Tag_query_error (query, Parse_errors.in_dir_tag_error \"bar\")) = \
         Terrat_tag_query.of_string query"
        (Error (`Tag_query_error (query, Parse_errors.in_dir_tag_error "bar"))
        = Terrat_tag_query.of_string query))

let test_quote_1 =
  Oth.test ~name:"Quote 1" (fun _ ->
      let query = of_string_exn "\"not\" \"and\" \"or\"" in
      let tag_set = Terrat_tag_set.of_list [ "not"; "and"; "or" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_quote_2 =
  Oth.test ~name:"Quote 2" (fun _ ->
      let query = of_string_exn "'not' 'and' 'or'" in
      let tag_set = Terrat_tag_set.of_list [ "not"; "and"; "or" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_quote_3 =
  Oth.test ~name:"Quote 3" (fun _ ->
      let query = of_string_exn "('not')" in
      let tag_set = Terrat_tag_set.of_list [ "not"; "and"; "or" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_quote_escape_1 =
  Oth.test ~name:"Quote escape 1" (fun _ ->
      let query = of_string_exn "'foo\\'bar'" in
      let tag_set = Terrat_tag_set.of_list [ "foo'bar" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_quote_escape_2 =
  Oth.test ~name:"Quote escape 2" (fun _ ->
      let query = of_string_exn "\"foo\\\"bar\"" in
      let tag_set = Terrat_tag_set.of_list [ "foo\"bar" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let test_deprecated_dir_glob =
  Oth.test ~name:"Deprecated dir glob" (fun _ ->
      let query = of_string_exn "dir~foo" in
      let tag_set = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo/bar/baz/zoom"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "Terrat_tag_query.match_ ~ctx ~tag_set query"
        (Terrat_tag_query.match_ ~ctx ~tag_set query))

let warning_of_string_exn s = Terrat_tag_query.warning (of_string_exn s)

let assert_no_warning s =
  Oth.Assert.none ~fail_msg:(Printf.sprintf "Unexpected warning for %S" s) (warning_of_string_exn s)

let assert_implicit_and ~suggestion s =
  match warning_of_string_exn s with
  | Some (Terrat_tag_query.Implicit_and { suggestion = actual }) ->
      Oth.Assert.Eq.string_option ~expected:suggestion ~actual
  | None -> Oth.Assert.false_ (Printf.sprintf "Expected an implicit and warning for %S" s)

let test_warning_implicit_and_dirs =
  Oth.test ~name:"Warning implicit and dirs" (fun _ ->
      assert_implicit_and ~suggestion:(Some "dir:foo or dir:bar") "dir:foo dir:bar";
      assert_implicit_and
        ~suggestion:(Some "dir:foo or dir:bar or dir:baz")
        "dir:foo dir:bar dir:baz")

let test_warning_implicit_and_dir_globs =
  Oth.test ~name:"Warning implicit and dir globs" (fun _ ->
      assert_implicit_and ~suggestion:(Some "dir~foo or dir:bar") "dir~foo dir:bar";
      assert_implicit_and ~suggestion:(Some "foo in dir or bar in dir") "foo in dir bar in dir")

let test_warning_implicit_and_mixed_with_or =
  Oth.test ~name:"Warning implicit and mixed with or" (fun _ ->
      (* A list of directories where one [or] was left out.  Every directory named
         is meant to be an alternative, so all of them go in the rewrite. *)
      assert_implicit_and
        ~suggestion:(Some "dir:a or dir:b or dir:c or dir:d")
        "dir:a or dir:b dir:c or dir:d";
      assert_implicit_and ~suggestion:(Some "dir:foo or dir:bar or dir:baz")
      @@ "(dir:foo or dir:bar) dir:baz";
      (* A directory repeated in the query is only offered once. *)
      assert_implicit_and ~suggestion:(Some "dir:a or dir:b") "dir:a or dir:b dir:a")

let test_warning_implicit_and_no_suggestion =
  Oth.test ~name:"Warning implicit and no suggestion" (fun _ ->
      (* An implicit and that is not a list of directories is a legitimate query,
         so it is reported without a rewrite. *)
      assert_implicit_and ~suggestion:None "dir:foo workspace:prod";
      assert_implicit_and ~suggestion:None "dir:foo dir:bar workspace:prod";
      assert_implicit_and ~suggestion:None "dir:foo not dir:bar";
      assert_implicit_and ~suggestion:None "dir:foo (dir:bar and dir:baz)")

let test_warning_explicit_operators =
  Oth.test ~name:"Warning explicit operators" (fun _ ->
      assert_no_warning "dir:foo and dir:bar";
      assert_no_warning "dir:foo or dir:bar";
      assert_no_warning "dir:foo";
      assert_no_warning "not dir:foo";
      assert_no_warning "(dir:foo or dir:bar) and workspace:prod";
      assert_no_warning "")

let test_warning_on_query =
  Oth.test ~name:"Warning on query" (fun _ ->
      (* The warning travels on the query itself, which is what makes it survive a
         round trip through storage. *)
      let query = of_string_exn "dir:foo dir:bar" in
      match Terrat_tag_query.warning query with
      | Some (Terrat_tag_query.Implicit_and { suggestion }) ->
          Oth.Assert.Eq.string_option ~expected:(Some "dir:foo or dir:bar") ~actual:suggestion
      | None -> Oth.Assert.false_ "Expected an implicit and warning")

let test_implicit_and_still_matches =
  Oth.test ~name:"Implicit and still matches" (fun _ ->
      (* The warning is a diagnostic, the query itself must be unchanged: whitespace
         is still an [and]. *)
      let query = of_string_exn "a b" in
      let dirspace = Terrat_change.Dirspace.{ dir = "foo"; workspace = "default" } in
      let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
      Oth.Assert.true_
        "matches when both tags are present"
        (Terrat_tag_query.match_ ~ctx ~tag_set:(Terrat_tag_set.of_list [ "a"; "b" ]) query);
      Oth.Assert.true_
        "does not match when only one tag is present"
        (not (Terrat_tag_query.match_ ~ctx ~tag_set:(Terrat_tag_set.of_list [ "a" ]) query)))

let matching_tag_sets q tag_sets =
  let query = of_string_exn q in
  let dirspace = Terrat_change.Dirspace.{ dir = "foo"; workspace = "default" } in
  let ctx = Terrat_tag_query.Ctx.make ~dirspace () in
  CCList.filter
    (fun tags -> Terrat_tag_query.match_ ~ctx ~tag_set:(Terrat_tag_set.of_list tags) query)
    tag_sets

let test_implicit_and_binds_like_and =
  Oth.test ~name:"Implicit and binds like and" (fun _ ->
      (* Juxtaposition is an [and] and has to bind exactly as tightly as one.  Before
         the parser gave the rule a precedence, `a b or c` parsed as `a and (b or c)`
         and an implicit and swallowed the whole rest of the expression. *)
      let tag_sets = [ [ "a"; "b" ]; [ "a" ]; [ "b" ]; [ "c" ]; [ "a"; "c" ] ] in
      Oth.Assert.Eq.list
        ~eq:(CCList.equal CCString.equal)
        ~pp:(CCList.pp CCString.pp)
        ~expected:(matching_tag_sets "a and b or c" tag_sets)
        ~actual:(matching_tag_sets "a b or c" tag_sets);
      Oth.Assert.Eq.list
        ~eq:(CCList.equal CCString.equal)
        ~pp:(CCList.pp CCString.pp)
        ~expected:(matching_tag_sets "c or a and b" tag_sets)
        ~actual:(matching_tag_sets "c or a b" tag_sets))

let test =
  Oth.parallel
    [
      test_simple_match;
      test_simple_no_match;
      test_simple_and;
      test_and;
      test_dir_glob_at_start;
      test_dir_glob_inner;
      test_dir_glob_at_end;
      test_dir_glob_cross_dirs;
      test_dir_glob_not_match_partial;
      test_dir_glob_no_match_with_slashes;
      test_bad_glob;
      test_query_with_extra_spaces;
      test_complex_query_match;
      test_complex_query_no_match;
      test_empty_query;
      test_and;
      test_and_precedence_1;
      test_and_precedence_2;
      test_and_precedence_3;
      test_or_1;
      test_or_2;
      test_parens_1;
      test_parens_with_and;
      test_parens_with_or;
      test_parens_2;
      test_parens_no_match_1;
      test_not_1;
      test_not_2;
      test_not_3;
      test_not_4;
      test_not_5;
      test_not_6;
      test_complex_1;
      test_complex_2;
      test_to_string;
      test_parse_failure_1;
      test_parse_failure_2;
      test_parse_failure_3;
      test_parse_failure_4;
      test_parse_failure_5;
      test_parse_failure_6;
      test_parse_failure_7;
      test_parse_failure_8;
      test_parse_failure_9;
      test_parse_failure_10;
      test_parse_failure_11;
      test_parse_failure_12;
      test_parse_failure_13;
      test_parse_failure_14;
      test_parse_failure_15;
      test_quote_1;
      test_quote_2;
      test_quote_3;
      test_quote_escape_1;
      test_quote_escape_2;
      test_deprecated_dir_glob;
      test_warning_implicit_and_dirs;
      test_warning_implicit_and_dir_globs;
      test_warning_implicit_and_mixed_with_or;
      test_warning_implicit_and_no_suggestion;
      test_warning_explicit_operators;
      test_warning_on_query;
      test_implicit_and_still_matches;
      test_implicit_and_binds_like_and;
    ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
