(* The whole config is printed to stdout at startup (see Sgs_cli.server), so any secret reachable
   from it lands in the logs of every deployment. *)

let private_key = "-----BEGIN PRIVATE KEY-----MIIEvQIBADANBgkqh-----END PRIVATE KEY-----"

let service_account_json =
  Printf.sprintf
    {|{"type":"service_account","project_id":"p","private_key":"%s","client_email":"sa@p.iam.gserviceaccount.com"}|}
    private_key

let set_env () =
  CCList.iter
    (fun (k, v) -> Unix.putenv k v)
    [
      ("STATEGRAPH_UI_BASE", "https://example.com");
      ("DB_HOST", "localhost");
      ("DB_USER", "sg");
      ("DB_PASS", "hunter2-should-not-print");
      ("DB_NAME", "sg");
      ("STATEGRAPH_OAUTH_TYPE", "google");
      ("STATEGRAPH_OAUTH_CLIENT_ID", "client-id");
      ("STATEGRAPH_OAUTH_CLIENT_SECRET", "client-secret-should-not-print");
      ("STATEGRAPH_OAUTH_COOKIE_SECRET", "0123456789abcdef");
      ("STATEGRAPH_OAUTH_GOOGLE_GROUP", "eng@example.com");
      ("STATEGRAPH_OAUTH_GOOGLE_SERVICE_ACCOUNT_JSON", service_account_json);
    ]

let test =
  Oth.serial
    [
      Oth.test ~name:"startup config print masks the Google service account key" (fun _ ->
          set_env ();
          let config = Oth.Assert.ok_pp ~pp:Sgs_config.pp_err (Sgs_config.create ()) in
          let shown = Sgs_config.show config in
          Oth.Assert.str_doesnt_contain ~haystack:shown ~needle:private_key;
          Oth.Assert.str_doesnt_contain ~haystack:shown ~needle:"client_email";
          (* Still shows whether one is configured, just not its contents. *)
          Oth.Assert.str_contains
            ~haystack:shown
            ~needle:"google_service_account_json = (Some <opaque>)");
      Oth.test ~name:"startup config print masks the other secrets too" (fun _ ->
          set_env ();
          let config = Oth.Assert.ok_pp ~pp:Sgs_config.pp_err (Sgs_config.create ()) in
          let shown = Sgs_config.show config in
          Oth.Assert.str_doesnt_contain ~haystack:shown ~needle:"hunter2-should-not-print";
          Oth.Assert.str_doesnt_contain ~haystack:shown ~needle:"client-secret-should-not-print");
    ]

let () = Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
