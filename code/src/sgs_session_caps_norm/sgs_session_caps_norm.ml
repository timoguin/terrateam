let normalize caps =
  let open Sgs_session_caps_capabilities in
  let canon = Sg_caps_match.canonicalize_list in
  let canon_opt = CCOption.map canon in
  let canon_states =
    CCOption.map (fun s ->
        let additional =
          Sln_map.String.map (CCOption.map canon) (Sgs_session_caps_states.additional s)
        in
        Sgs_session_caps_states.make ~additional Json_schema.Empty_obj.t)
  in
  let canon_preview { Sgs_session_caps_preview.states; subgraph; tenants } =
    {
      Sgs_session_caps_preview.states = canon_states states;
      subgraph = canon_states subgraph;
      tenants = canon_opt tenants;
    }
  in
  let canon_commit { Sgs_session_caps_commit.states; subgraph; tenants } =
    {
      Sgs_session_caps_commit.states = canon_states states;
      subgraph = canon_states subgraph;
      tenants = canon_opt tenants;
    }
  in
  let canon_admin { Sgs_session_caps_admin.tenants } =
    { Sgs_session_caps_admin.tenants = canon_opt tenants }
  in
  let canon_sudo { Sgs_session_caps_sudo.users } = { Sgs_session_caps_sudo.users = canon users } in
  let canon_users_manage { Sgs_session_caps_users_manage.tenants } =
    { Sgs_session_caps_users_manage.tenants = canon_opt tenants }
  in
  {
    caps with
    admin = CCOption.map canon_admin caps.admin;
    commit = CCOption.map canon_commit caps.commit;
    preview = CCOption.map canon_preview caps.preview;
    sudo = CCOption.map canon_sudo caps.sudo;
    users_manage = CCOption.map canon_users_manage caps.users_manage;
  }
