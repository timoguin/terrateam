(* stategraph/stategraph#1675.  A comment written by a GitHub App was dropped
   with no trace.  [Terrat_github_webhooks_app] made [external_url] and [owner]
   mandatory and non-null, so the strict decode of [issue_comment$created]
   failed on a [performed_via_github_app] that did not agree, the any_of fell
   through to [issue$any] -- which has no [comment] field and accepts any
   [action] -- and the handler answered 200 with NOOP : ISSUE.

   [Terrat_github_webhooks_issue.t] carries the same field, and [issue$any]
   holds that same [issue], so an App-opened pull request took BOTH choices
   down and stopped comments from people too.

   These tests pin the decode, not the shape of the App object.  Nothing in the
   tree reads an [App] field, so no delivered App payload may refuse a
   command. *)

open Terrat_github_webhooks_fixtures

let app ?edit () =
  match edit with
  | Some edit -> edit (json_of_string app_payload)
  | None -> json_of_string app_payload

(* An App's login keeps its [bot] suffix and its user type is Bot.  A fixture
   that changes [performed_via_github_app] without changing the author would
   not be a payload GitHub ever sends. *)
let as_bot =
  let bot user =
    user |> set_member "login" (`String "some-bot[bot]") |> set_member "type" (`String "Bot")
  in
  fun json ->
    json |> update_member "sender" bot |> update_member "comment" (update_member "user" bot)

let comment_by_app app json =
  as_bot json |> update_member "comment" (set_member "performed_via_github_app" app)

let issue_opened_by_app app = update_member "issue" (set_member "performed_via_github_app" app)

let test_app ~name edit =
  Oth.test ~tags:[ "github_webhooks" ] ~name (fun _ ->
      ignore
        (Oth.Assert.ok_show ~show:CCFun.id (Terrat_github_webhooks.App.of_yojson (app ~edit ())));
      ())

let test_app_full = test_app ~name:"App: a full object decodes" CCFun.id

let test_app_external_url_null =
  test_app ~name:"App: a null external_url decodes" (set_member "external_url" `Null)

let test_app_external_url_absent =
  test_app ~name:"App: an absent external_url decodes" (remove_member "external_url")

let test_app_owner_null = test_app ~name:"App: a null owner decodes" (set_member "owner" `Null)
let test_app_owner_absent = test_app ~name:"App: an absent owner decodes" (remove_member "owner")

let test_app_empty_object =
  test_app ~name:"App: an object with no members decodes" (fun _ -> `Assoc [])

let show_choice = function
  | Terrat_github_webhooks.Issue_comment_event.Issue_comment_created _ -> "Issue_comment_created"
  | Terrat_github_webhooks.Issue_comment_event.Issue_comment_deleted _ -> "Issue_comment_deleted"
  | Terrat_github_webhooks.Issue_comment_event.Issue_comment_edited _ -> "Issue_comment_edited"
  | Terrat_github_webhooks.Issue_comment_event.Issue_any _ -> "Issue_any"

let test_event ~name ~expected edit =
  Oth.test ~tags:[ "github_webhooks" ] ~name (fun _ ->
      let choice =
        Oth.Assert.ok_show
          ~show:CCFun.id
          (Terrat_github_webhooks.Issue_comment_event.of_yojson
             (edit (json_of_string base_payload)))
      in
      Oth.Assert.Eq.string ~expected ~actual:(show_choice choice);
      ())

(* The control: the payload a person's comment makes. *)
let test_person_comment =
  test_event
    ~name:"a comment from a person is Issue_comment_created"
    ~expected:"Issue_comment_created"
    CCFun.id

let test_app_comment_full =
  test_event
    ~name:"a comment from an App with a full App object is Issue_comment_created"
    ~expected:"Issue_comment_created"
    (comment_by_app (app ()))

let test_app_comment_external_url_null =
  test_event
    ~name:"a comment from an App with a null external_url is Issue_comment_created"
    ~expected:"Issue_comment_created"
    (comment_by_app (app ~edit:(set_member "external_url" `Null) ()))

let test_app_comment_external_url_absent =
  test_event
    ~name:"a comment from an App with no external_url is Issue_comment_created"
    ~expected:"Issue_comment_created"
    (comment_by_app (app ~edit:(remove_member "external_url") ()))

let test_app_comment_owner_null =
  test_event
    ~name:"a comment from an App with a null owner is Issue_comment_created"
    ~expected:"Issue_comment_created"
    (comment_by_app (app ~edit:(set_member "owner" `Null) ()))

(* The effect the report does not name.  An App opened the pull request and the
   comment is a person's.  Before the fix this took Issue_comment_created AND
   issue$any down, so the whole event decode failed and the server answered
   500 for every comment on that pull request. *)
let test_person_comment_on_app_pull_request =
  test_event
    ~name:"a comment from a person on an App-opened pull request is Issue_comment_created"
    ~expected:"Issue_comment_created"
    (issue_opened_by_app (app ~edit:(set_member "external_url" `Null) ()))

(* A push event built from the repository and the sender of [base_payload]. *)
let push ~compare ~head_commit =
  let base = json_of_string base_payload in
  let member key =
    match base with
    | `Assoc fields -> CCList.assoc ~eq:CCString.equal key fields
    | _ -> assert false
  in
  `Assoc
    [
      ("ref", `String "refs/heads/main");
      ("before", `String "2a7d17207d0000000000000000000000000000000");
      ("after", `String "c50350e26cbf7c7fe1b89ecf3e252f984bd72d3b");
      ("created", `Bool false);
      ("deleted", `Bool false);
      ("forced", `Bool true);
      ("base_ref", `Null);
      ("compare", compare);
      ("commits", `List []);
      ("head_commit", head_commit);
      ("repository", member "repository");
      ("pusher", `Assoc [ ("name", `String "someone"); ("email", `String "someone@example.com") ]);
      ("sender", member "sender");
    ]

let head_commit =
  let person = `Assoc [ ("name", `String "someone"); ("email", `String "someone@example.com") ] in
  `Assoc
    [
      ("id", `String "c50350e26cbf7c7fe1b89ecf3e252f984bd72d3b");
      ("tree_id", `String "5f0e0e7f1c1c9a2f3b8d0c7a0f1b2c3d4e5f6a7b");
      ("distinct", `Bool true);
      ("message", `String "a commit");
      ("timestamp", `String "2026-09-24T18:18:15Z");
      ("url", `String "https://github.com/owner/repo/commit/c50350e2");
      ("author", person);
      ("committer", person);
      ("added", `List []);
      ("removed", `List []);
      ("modified", `List []);
    ]

let test_push ~name json =
  Oth.test ~tags:[ "github_webhooks" ] ~name (fun _ ->
      ignore (Oth.Assert.ok_show ~show:CCFun.id (Terrat_github_webhooks.Push_event.of_yojson json));
      ())

(* The control: a push with its comparison and its head commit. *)
let test_push_full =
  test_push
    ~name:"push: a push with a compare and a head commit decodes"
    (push
       ~compare:(`String "https://github.com/owner/repo/compare/2a7d1720...c50350e2")
       ~head_commit)

(* GitHub can deliver a push with a null [compare], a null [head_commit] and no commits.  A push to
   the default branch updates the drift schedules of the repository, thus such a push must not be
   dropped. *)
let test_push_null_compare_and_head_commit =
  test_push
    ~name:"push: a push with a null compare and a null head commit decodes"
    (push ~compare:`Null ~head_commit:`Null)

let test =
  Oth.parallel
    [
      test_push_full;
      test_push_null_compare_and_head_commit;
      test_app_full;
      test_app_external_url_null;
      test_app_external_url_absent;
      test_app_owner_null;
      test_app_owner_absent;
      test_app_empty_object;
      test_person_comment;
      test_app_comment_full;
      test_app_comment_external_url_null;
      test_app_comment_external_url_absent;
      test_app_comment_owner_null;
      test_person_comment_on_app_pull_request;
    ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
