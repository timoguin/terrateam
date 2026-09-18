include
  Terrat_vcs_api.S
    with type Account.Id.t = int
     and type Config.vcs_config = Terrat_config.Gitlab.t
     and type Client.native = Openapic_abb.t
     and type User.Id.t = string
     and type Pull_request.Id.t = int
     and type Repo.Id.t = int

(** What a response that may be a rate limit rejection warrants. [`No_wait] if it is not one,
    [`Wait secs] to back off for [secs] and try again, and [`Fail secs] when [secs] is longer than
    [max_wait]. [max_wait] is the time budget the call was given: a back off longer than the budget
    cannot be honoured without overrunning it, thus the call gives up rather than sleeps.

    GitLab signals a rate limit with status 403 or 429 and the unprefixed [ratelimit-*] headers.

    The clock comes in as [now] rather than being read here, so the policy can be exercised without
    a scheduler.

    {v
      headers:[ ("retry-after", "5") ] ~status:429 ~max_wait:20.0  ->  `Wait 5.0
      headers:[ ("retry-after", "3600") ] ~status:429 ~max_wait:20.0  ->  `Fail 3600.0
    v} *)
val rate_limit_decision :
  headers:(string * string) list ->
  status:int ->
  now:float ->
  max_wait:float ->
  [ `Fail of float | `Wait of float | `No_wait ]
