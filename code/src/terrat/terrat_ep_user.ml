module Installations = struct
  module Sql = struct
    let select_installations () =
      Pgsql_io.Typed_sql.(
        sql
        // (* id *) Ret.bigint
        // (* login *) Ret.text
        /^ "select id, login from github_installations where id = ANY($installation_ids)"
        /% Var.(array (bigint "installation_ids")))

    let insert_user_installations () =
      Pgsql_io.Typed_sql.(
        sql
        /^ "insert into github_user_installations (user_id, installation_id) select * from \
            unnest($user, $installation) on conflict (user_id, installation_id) do nothing"
        /% Var.(array (uuid "user"))
        /% Var.(array (bigint "installation")))
  end

  let get' config storage user =
    let open Abbs_future_combinators.Infix_result_monad in
    Terrat_github_user.get_token config storage user
    >>= fun token ->
    Terrat_github.with_client config (`Bearer token) Terrat_github.get_user_installations
    >>= fun installations ->
    Pgsql_pool.with_conn storage ~f:(fun db ->
        let module I = Githubc2_components.Installation in
        (* This insert will fail if we miss the webhook that an installation has
           occurred.  The user will probably need to remove and install again. *)
        Pgsql_io.Prepared_stmt.execute
          db
          (Sql.insert_user_installations ())
          (CCList.replicate (CCList.length installations) (Terrat_user.id user))
          (CCList.map (fun I.{ primary = Primary.{ id; _ }; _ } -> Int64.of_int id) installations)
        >>= fun () ->
        Pgsql_io.Prepared_stmt.fetch
          db
          (Sql.select_installations ())
          ~f:(fun id name ->
            Terrat_api_components.Installation.
              { id = CCInt64.to_string id; name; type_ = Type.Installation_type_github "github" })
          (CCList.map (fun I.{ primary = Primary.{ id; _ }; _ } -> Int64.of_int id) installations))

  let get config storage =
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        let open Abb.Future.Infix_monad in
        get' config storage user
        >>= function
        | Ok installations ->
            let body =
              Terrat_api_user.List_installations.Responses.OK.(
                { installations } |> to_yojson |> Yojson.Safe.to_string)
            in
            Abb.Future.return (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m "USER : %s : GET : INSTALLATIONS : %a" (Brtl_ctx.token ctx) Pgsql_pool.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m ->
                m "USER : %s : GET : INSTALLATIONS : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Terrat_github.get_user_installations_err as err) ->
            Logs.err (fun m ->
                m
                  "USER : %s : GET : INSTALLATIONS : %a"
                  (Brtl_ctx.token ctx)
                  Terrat_github.pp_get_user_installations_err
                  err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
        | Error (#Terrat_github_user.err as err) ->
            Logs.err (fun m ->
                m
                  "USER : %s : GET : INSTALLATIONS : %a"
                  (Brtl_ctx.token ctx)
                  Terrat_github_user.pp_err
                  err);
            Abb.Future.return
              (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
end