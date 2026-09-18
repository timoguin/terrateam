(* The call timeout the tests bound against.  It matches the shipped default of
   [TERRAT_VCS_CALL_TIMEOUT] so that the cases read the way a deployment
   behaves. *)
let max_wait = 20.0

let decision ?(status = 429) ?(now = 1000.0) headers =
  Terrat_vcs_api_gitlab.rate_limit_decision ~headers ~status ~now ~max_wait

let assert_wait ~expected = function
  | `Wait w -> Oth.Assert.true_ ~fail_msg:"unexpected wait" (CCFloat.abs (w -. expected) < 0.001)
  | `Fail _ -> Oth.Assert.false_ "expected `Wait, got `Fail"
  | `No_wait -> Oth.Assert.false_ "expected `Wait, got `No_wait"

let assert_fail = function
  | `Fail _ -> ()
  | `Wait _ -> Oth.Assert.false_ "expected `Fail, got `Wait"
  | `No_wait -> Oth.Assert.false_ "expected `Fail, got `No_wait"

let assert_no_wait = function
  | `No_wait -> ()
  | `Wait _ -> Oth.Assert.false_ "expected `No_wait, got `Wait"
  | `Fail _ -> Oth.Assert.false_ "expected `No_wait, got `Fail"

let test_success_is_not_a_rate_limit =
  Oth.test ~name:"a 200 is not a rate limit" (fun _ ->
      assert_no_wait (decision ~status:200 [ ("ratelimit-remaining", "0") ]);
      ())

(* GitLab answers a rate limit with 429, so detecting 403 alone leaves the
   handling dead for the status that actually occurs. *)
let test_429_is_detected =
  Oth.test ~name:"a 429 with retry-after is a rate limit" (fun _ ->
      assert_wait ~expected:5.0 (decision ~status:429 [ ("retry-after", "5") ]);
      ())

let test_403_is_detected =
  Oth.test ~name:"a 403 with retry-after is a rate limit" (fun _ ->
      assert_wait ~expected:5.0 (decision ~status:403 [ ("retry-after", "5") ]);
      ())

let test_other_status_is_not_a_rate_limit =
  Oth.test ~name:"a 500 with retry-after is not a rate limit" (fun _ ->
      assert_no_wait (decision ~status:500 [ ("retry-after", "5") ]);
      ())

let test_retry_after_beyond_timeout_fails_fast =
  Oth.test ~name:"retry-after beyond the call timeout fails fast" (fun _ ->
      assert_fail (decision [ ("retry-after", "3600") ]);
      ())

(* The 60s substitute for an unreadable header is above the 20s call timeout on
   purpose: a wait we cannot read is a wait we will not gamble on. *)
let test_unparseable_retry_after_fails_fast =
  Oth.test ~name:"unparseable retry-after fails fast" (fun _ ->
      assert_fail (decision [ ("retry-after", "soon") ]);
      ())

let test_reset_within_timeout_waits =
  Oth.test ~name:"a reset inside the call timeout waits" (fun _ ->
      assert_wait
        ~expected:5.0
        (decision ~now:1000.0 [ ("ratelimit-remaining", "0"); ("ratelimit-reset", "1005") ]);
      ())

(* Without the old one-minute floor a reset that has already passed would be a
   negative sleep, so the wait is clamped at zero. *)
let test_reset_already_past_is_a_zero_wait =
  Oth.test ~name:"a reset already past is a zero wait, not a negative one" (fun _ ->
      assert_wait
        ~expected:0.0
        (decision ~now:1000.0 [ ("ratelimit-remaining", "0"); ("ratelimit-reset", "900") ]);
      ())

let test_reset_beyond_timeout_fails_fast =
  Oth.test ~name:"a reset beyond the call timeout fails fast" (fun _ ->
      assert_fail
        (decision ~now:1000.0 [ ("ratelimit-remaining", "0"); ("ratelimit-reset", "4600") ]);
      ())

let test_remaining_above_zero_is_not_a_rate_limit =
  Oth.test ~name:"remaining above zero is not a rate limit" (fun _ ->
      assert_no_wait
        (decision ~now:1000.0 [ ("ratelimit-remaining", "17"); ("ratelimit-reset", "4600") ]);
      ())

let test_headers_are_case_insensitive =
  Oth.test ~name:"header lookup ignores case" (fun _ ->
      assert_wait ~expected:5.0 (decision [ ("Retry-After", "5") ]);
      ())

let () =
  Oth.run
    ~file:__FILE__
    ~setup:(fun () -> Ok ())
    ~teardown:(fun _ -> ())
    (fun _ ->
      Oth.serial
        [
          test_success_is_not_a_rate_limit;
          test_429_is_detected;
          test_403_is_detected;
          test_other_status_is_not_a_rate_limit;
          test_retry_after_beyond_timeout_fails_fast;
          test_unparseable_retry_after_fails_fast;
          test_reset_within_timeout_waits;
          test_reset_already_past_is_a_zero_wait;
          test_reset_beyond_timeout_fails_fast;
          test_remaining_above_zero_is_not_a_rate_limit;
          test_headers_are_case_insensitive;
        ])
