let marked_comment_is_from_self =
  Oth.test ~name:"marked comment is from self" (fun _ ->
      let body = Terrat_comment.add_self_marker "## Plan Output" in
      Oth.Assert.true_ "marked body is from self" (Terrat_comment.is_from_self body);
      ())

let plain_comment_is_not_from_self =
  Oth.test ~name:"plain comment is not from self" (fun _ ->
      Oth.Assert.not_true
        "a command is not from self"
        (Terrat_comment.is_from_self "terrateam plan");
      Oth.Assert.not_true "an empty body is not from self" (Terrat_comment.is_from_self "");
      ())

(* The marker closes the body, so the command parser still reads the first word
   of what was published. *)
let marker_keeps_the_body_first =
  Oth.test ~name:"marker keeps the body first" (fun _ ->
      let body = Terrat_comment.add_self_marker "terrateam plan" in
      Oth.Assert.Eq.string
        ~expected:"terrateam plan"
        ~actual:(CCString.take (CCString.length "terrateam plan") body);
      Oth.Assert.true_ "the marked body is from self" (Terrat_comment.is_from_self body);
      ())

(* A quote-reply copies the raw markdown of the quoted comment, marker
   included, and the person's command follows it.  Such a body carries the
   marker but is NOT from self: the command must still run. *)
let quoted_marked_comment_is_not_from_self =
  Oth.test ~name:"quoted marked comment is not from self" (fun _ ->
      let quoted =
        Terrat_comment.add_self_marker "## Plan Output"
        |> CCString.split_on_char '\n'
        |> CCList.map (fun line -> "> " ^ line)
        |> CCString.concat "\n"
      in
      let body = quoted ^ "\n\nterrateam apply" in
      Oth.Assert.not_true "a quote-reply is not from self" (Terrat_comment.is_from_self body);
      ())

(* Trailing white space around the marker must not hide it. *)
let trailing_whitespace_keeps_the_marker =
  Oth.test ~name:"trailing whitespace keeps the marker" (fun _ ->
      let body = Terrat_comment.add_self_marker "## Plan Output" ^ "\n" in
      Oth.Assert.true_ "a trailing newline is ignored" (Terrat_comment.is_from_self body);
      ())

let test =
  Oth.parallel
    [
      marked_comment_is_from_self;
      plain_comment_is_not_from_self;
      marker_keeps_the_body_first;
      quoted_marked_comment_is_not_from_self;
      trailing_whitespace_keeps_the_marker;
    ]

let () = Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
