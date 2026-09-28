let run _config _storage =
  Brtl_ep.run_json ~f:(fun ctx ->
      let module R = Sgs_api_components_license_status_response in
      let body =
        Yojson.Safe.to_string
        @@ R.to_yojson { R.licensed = false; required = false; source = "none" }
      in
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
