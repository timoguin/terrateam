let ctx = Terrat_base_repo_config_v1.Ctx.make ~dest_branch:"main" ~branch:"test" ()

(* [Terrat_base_repo_config_v1.derive] reports a glob it cannot parse rather than
   raising.  Unwrap it with the assertion so a test that trips over one says which
   glob and why, instead of dying on a bare exception. *)
let derive ~ctx ~index ~file_list repo_config =
  Oth.Assert.ok_pp
    ~pp:Terrat_base_repo_config_v1.pp_derive_err
    (Terrat_base_repo_config_v1.derive ~ctx ~index ~file_list repo_config)

let depends_on_q ?(prune_on_no_change = false) s =
  {
    Terrat_base_repo_config_v1.Depends_on.tag_query =
      CCResult.get_exn (Terrat_tag_query.of_string s);
    prune_on_no_change;
  }

(* This configuration is used for tests of the dirs configuration *)
let dirs_config =
  let module R = Terrat_base_repo_config_v1 in
  let default_file_patterns =
    [
      CCResult.get_exn (R.File_pattern.make "${DIR}/*.tf");
      CCResult.get_exn (R.File_pattern.make "${DIR}/*.tfvars");
      CCResult.get_exn (R.File_pattern.make "${DIR}/*.json");
    ]
  in
  let when_modified =
    R.When_modified.make ~autoapply:true ~autoplan:false ~file_patterns:default_file_patterns ()
  in
  R.of_view
    (R.View.make
       ~when_modified
       ~dirs:
         (Sln_map.String.of_list
            [
              ( "iam",
                R.Dirs.Dir.make
                  ~workspaces:
                    (Sln_map.String.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:
                               {
                                 when_modified with
                                 R.When_modified.autoplan = false;
                                 file_patterns =
                                   [ CCResult.get_exn (R.File_pattern.make "iam/*.tf") ];
                               }
                             () );
                       ])
                  () );
              ( "ebl",
                R.Dirs.Dir.make
                  ~workspaces:
                    (Sln_map.String.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:
                               {
                                 when_modified with
                                 R.When_modified.autoapply = true;
                                 file_patterns =
                                   [
                                     CCResult.get_exn (R.File_pattern.make "ebl/*.tf");
                                     CCResult.get_exn (R.File_pattern.make "ebl_modules");
                                   ];
                               }
                             () );
                       ])
                  () );
              ( "ec2",
                R.Dirs.Dir.make
                  ~workspaces:
                    (Sln_map.String.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:
                               {
                                 when_modified with
                                 (* This actually has an error in that it does not
                                    match files in the ec2 directory, this error is
                                    on purpose used for testing. *)
                                 R.When_modified.file_patterns =
                                   [ CCResult.get_exn (R.File_pattern.make "iam/*.tf") ];
                               }
                             () );
                       ])
                  () );
              ( "s3",
                R.Dirs.Dir.make
                  ~tags:[ "s3" ]
                  ~workspaces:
                    (Sln_map.String.of_list
                       [ ("default", R.Dirs.Workspace.make ~when_modified ()) ])
                  () );
              ( "lambda",
                R.Dirs.Dir.make
                  ~workspaces:
                    (Sln_map.String.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:{ when_modified with R.When_modified.autoplan = true }
                             () );
                       ])
                  () );
              ( "module",
                R.Dirs.Dir.make
                  ~workspaces:
                    (Sln_map.String.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:
                               { when_modified with R.When_modified.file_patterns = [] }
                             () );
                       ])
                  () );
            ])
       ())

(* this config makes the mistake of having a directory that matches everything *)
let bad_dirs_config =
  let module R = Terrat_base_repo_config_v1 in
  R.of_view
    (R.View.make
       ~dirs:
         (Sln_map.String.of_list
            [
              ( "iam",
                R.Dirs.Dir.make
                  ~workspaces:
                    (Sln_map.String.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:
                               (R.When_modified.make
                                  ~file_patterns:
                                    [ CCResult.get_exn (R.File_pattern.make "iam/*.tf") ]
                                  ())
                             () );
                       ])
                  () );
              ( "ebl",
                R.Dirs.Dir.make
                  ~workspaces:
                    (Sln_map.String.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:
                               (R.When_modified.make
                                  ~file_patterns:
                                    [
                                      CCResult.get_exn (R.File_pattern.make "ebl/*.tf");
                                      CCResult.get_exn (R.File_pattern.make "ebl_modules");
                                    ]
                                  ())
                             () );
                       ])
                  () );
              ( "ec2",
                R.Dirs.Dir.make
                  ~workspaces:
                    (Sln_map.String.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:
                               (R.When_modified.make
                                (* This should only match changes in the root
                                   directory, no subdirs *)
                                  ~file_patterns:[ CCResult.get_exn (R.File_pattern.make "*.tf") ]
                                  ())
                             () );
                       ])
                  () );
              ( "s3",
                R.Dirs.Dir.make
                  ~workspaces:
                    (Sln_map.String.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:
                               (R.When_modified.make
                                  ~file_patterns:
                                    [ CCResult.get_exn (R.File_pattern.make "**/*.tf") ]
                                  ())
                             () );
                       ])
                  () );
            ])
       ())

let test_simple =
  Oth.test ~name:"Test simple" (fun _ ->
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf" ]
          Terrat_base_repo_config_v1.default
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = Terrat_change_match3.match_diff_list dirs diff in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes))

let test_workflow_idx =
  Oth.test ~name:"Test workflow idx" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf" ]
          (R.of_view
             (R.View.make
                ~workflows:
                  [
                    R.Workflows.Entry.make
                      ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string "workspace:default"))
                      ~plan:
                        [
                          R.Workflows.Entry.Op.Run
                            (R.Workflow_step.Run.make ~cmd:[ "echo"; "hi" ] ());
                        ]
                      ();
                  ]
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes);
      let change = CCList.hd changes in
      let workflows = Terrat_base_repo_config_v1.workflows repo_config in
      let workflow_idx =
        CCOption.map
          fst
          (CCList.find_idx
             (fun { Terrat_base_repo_config_v1.Workflows.Entry.tag_query; _ } ->
               Terrat_change_match3.match_tag_query ~tag_query change)
             workflows)
      in
      Oth.Assert.true_ (workflow_idx = Some 0))

let test_workflow_idx_tag_in_dir =
  Oth.test
    ~name:"Test workflow idx tag in dir"
    ~desc:"Test workflow idx matches when tag is in dirs"
    (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf" ]
          (R.of_view
             (R.View.make
                ~workflows:
                  [
                    R.Workflows.Entry.make
                      ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string "ec2"))
                      ~plan:
                        [
                          R.Workflows.Entry.Op.Run
                            (R.Workflow_step.Run.make ~cmd:[ "echo"; "hi" ] ());
                        ]
                      ();
                  ]
                ~dirs:(Sln_map.String.of_list [ ("ec2", R.Dirs.Dir.make ~tags:[ "ec2" ] ()) ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes);
      let change = CCList.hd changes in
      let workflows = Terrat_base_repo_config_v1.workflows repo_config in
      let workflow_idx =
        CCOption.map
          fst
          (CCList.find_idx
             (fun { Terrat_base_repo_config_v1.Workflows.Entry.tag_query; _ } ->
               Terrat_change_match3.match_tag_query ~tag_query change)
             workflows)
      in
      Oth.Assert.true_ (workflow_idx = Some 0))

let test_workflow_idx_multiple_dirs =
  Oth.test
    ~name:"Test workflow idx multiple dirs"
    ~desc:"Test workflow idx matches when tag is in dirs with multiple dirs changed"
    (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf"; "s3/s3.tf" ]
          (R.of_view
             (R.View.make
                ~workflows:
                  [
                    R.Workflows.Entry.make
                      ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string "ec2"))
                      ~plan:
                        [
                          R.Workflows.Entry.Op.Run
                            (R.Workflow_step.Run.make ~cmd:[ "echo"; "hi" ] ());
                        ]
                      ();
                  ]
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ("ec2", R.Dirs.Dir.make ~tags:[ "ec2" ] ());
                       ("s3", R.Dirs.Dir.make ~tags:[ "s3" ] ());
                     ])
                ()))
      in
      let diff =
        Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" }; Add { filename = "s3/s3.tf" } ]
      in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:2 ~actual:(CCList.length changes);
      let change =
        CCList.hd
          (CCList.filter
             (fun { Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ }; _ }
                -> dir = "ec2")
             changes)
      in
      let workflows = Terrat_base_repo_config_v1.workflows repo_config in
      let workflow_idx =
        CCOption.map
          fst
          (CCList.find_idx
             (fun { Terrat_base_repo_config_v1.Workflows.Entry.tag_query; _ } ->
               Terrat_change_match3.match_tag_query ~tag_query change)
             workflows)
      in
      Oth.Assert.true_ (workflow_idx = Some 0))

let test_workflow_override =
  Oth.test ~name:"Test overriding workflow for all" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf"; "s3/s3.tf" ]
          (R.of_view
             (R.View.make
                ~workflows:
                  [
                    R.Workflows.Entry.make
                      ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string ""))
                      ~plan:
                        [
                          R.Workflows.Entry.Op.Run
                            (R.Workflow_step.Run.make ~cmd:[ "echo"; "hi" ] ());
                        ]
                      ();
                  ]
                ()))
      in
      let diff =
        Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" }; Add { filename = "s3/s3.tf" } ]
      in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:2 ~actual:(CCList.length changes);
      let workflows = Terrat_base_repo_config_v1.workflows repo_config in
      CCList.iter
        (fun change ->
          let workflow_idx =
            CCOption.map
              fst
              (CCList.find_idx
                 (fun { Terrat_base_repo_config_v1.Workflows.Entry.tag_query; _ } ->
                   Terrat_change_match3.match_tag_query ~tag_query change)
                 workflows)
          in
          Oth.Assert.true_ (workflow_idx = Some 0))
        changes)

let test_dir_match =
  Oth.test ~name:"Test dir match" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf"; "s3/s3.tf" ]
          R.default
      in
      let diff =
        Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" }; Add { filename = "s3/s3.tf" } ]
      in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes =
        CCList.filter
          (Terrat_change_match3.match_tag_query
             ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string "dir:ec2")))
          (CCList.flatten (Terrat_change_match3.match_diff_list dirs diff))
      in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes))

let test_dirspace_map =
  Oth.test ~name:"Test dirspace map" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf"; "s3/s3.tf" ]
          R.default
      in
      let dirspaces =
        Terrat_change.Dirspace.
          [ { dir = "ec2"; workspace = "default" }; { dir = "s3"; workspace = "default" } ]
      in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes =
        CCList.filter
          (Terrat_change_match3.match_tag_query
             ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string "dir:ec2")))
          (CCList.flat_map
             CCFun.(Terrat_change_match3.of_dirspace dirs %> CCOption.to_list)
             dirspaces)
      in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes))

let test_dir_file_pattern =
  Oth.test ~name:"Test dir file pattern" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf"; "s3/s3.tf"; "iam/main.tf" ]
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "iam",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [ CCResult.get_exn (R.File_pattern.make "ec2/*.tf") ]
                                           ())
                                      () );
                                ])
                           () );
                       ("s3", R.Dirs.Dir.make ~tags:[ "s3" ] ());
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:2 ~actual:(CCList.length changes))

let test_dir_config_iam =
  Oth.test ~name:"Test Dir Config IAM" (fun _ ->
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "iam/foo.tf"; "ec2/ec2.tf"; "ebl/ebl.tf"; "lambda/lambda.tf" ]
          dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "iam/foo.tf" } ] in
      let dirs =
        match
          Terrat_change_match3.synthesize_config
            ~index:Terrat_base_repo_config_v1.Index.empty
            repo_config
        with
        | Ok dirs -> dirs
        | Error _ -> Oth.Assert.false_ "Test Dir Config IAM: unexpected value"
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      (* We match the iam and ec2 dir *)
      Oth.Assert.Eq.int ~expected:2 ~actual:(CCList.length changes);
      CCList.iter
        (fun {
               Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
               when_modified;
               _;
             }
           ->
          let module Wm = Terrat_base_repo_config_v1.When_modified in
          match dir with
          | "ec2" ->
              Oth.Assert.not_true when_modified.Wm.autoplan;
              Oth.Assert.true_ when_modified.Wm.autoapply
          | "iam" ->
              Oth.Assert.not_true when_modified.Wm.autoplan;
              Oth.Assert.true_ when_modified.Wm.autoapply
          | _ -> Oth.Assert.false_ "Test Dir Config IAM: unexpected value")
        changes)

let test_dir_config_ebl =
  Oth.test ~name:"Test Dir Config ebl" (fun _ ->
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "iam/foo.tf"; "ec2/ec2.tf"; "ebl/ebl.tf"; "lambda/lambda.tf" ]
          dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ebl/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes);
      CCList.iter
        (fun {
               Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
               when_modified;
               _;
             }
           ->
          let module Wm = Terrat_base_repo_config_v1.When_modified in
          match dir with
          | "ebl" ->
              Oth.Assert.not_true when_modified.Wm.autoplan;
              Oth.Assert.true_ when_modified.Wm.autoapply
          | _ -> Oth.Assert.false_ "Test Dir Config ebl: unexpected value")
        changes)

let test_dir_config_ebl_modules =
  Oth.test ~name:"Test Dir Config ebl modules" (fun _ ->
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "iam/foo.tf"; "ec2/ec2.tf"; "ebl/ebl.tf"; "lambda/lambda.tf"; "ebl_modules" ]
          dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ebl_modules" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes);
      CCList.iter
        (fun {
               Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
               when_modified;
               _;
             }
           ->
          let module Wm = Terrat_base_repo_config_v1.When_modified in
          match dir with
          | "ebl" ->
              Oth.Assert.not_true when_modified.Wm.autoplan;
              Oth.Assert.true_ when_modified.Wm.autoapply
          | _ -> Oth.Assert.false_ "Test Dir Config ebl modules: unexpected value")
        changes)

let test_dir_config_ebl_and_modules =
  Oth.test ~name:"Test Dir Config ebl and modules" (fun _ ->
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "iam/foo.tf"; "ec2/ec2.tf"; "ebl/ebl.tf"; "lambda/lambda.tf"; "ebl_modules" ]
          dirs_config
      in
      let diff =
        Terrat_change.Diff.[ Add { filename = "ebl_modules" }; Add { filename = "ebl/foo.tf" } ]
      in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes);
      CCList.iter
        (fun {
               Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
               when_modified;
               _;
             }
           ->
          let module Wm = Terrat_base_repo_config_v1.When_modified in
          match dir with
          | "ebl" ->
              Oth.Assert.not_true when_modified.Wm.autoplan;
              Oth.Assert.true_ when_modified.Wm.autoapply
          | _ -> Oth.Assert.false_ "Test Dir Config ebl and modules: unexpected value")
        changes)

let test_dir_config_s3 =
  Oth.test ~name:"Test Dir Config s3" (fun _ ->
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:
            [
              "iam/foo.tf";
              "ec2/ec2.tf";
              "ebl/ebl.tf";
              "lambda/lambda.tf";
              "ebl_modules";
              "s3/s3.tf";
            ]
          dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "s3/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes);
      CCList.iter
        (fun {
               Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
               when_modified;
               _;
             }
           ->
          let module Wm = Terrat_base_repo_config_v1.When_modified in
          match dir with
          | "s3" ->
              Oth.Assert.not_true when_modified.Wm.autoplan;
              Oth.Assert.true_ when_modified.Wm.autoapply
          | _ -> Oth.Assert.false_ "Test Dir Config s3: unexpected value")
        changes)

let test_dir_config_lambda_json =
  Oth.test ~name:"Test Dir Config lambda JSON" (fun _ ->
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:
            [ "iam/foo.tf"; "ec2/ec2.tf"; "ebl/ebl.tf"; "lambda/foo.tf"; "ebl_modules"; "s3/s3.tf" ]
          dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "lambda/foo.json" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes);
      CCList.iter
        (fun {
               Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
               when_modified;
               _;
             }
           ->
          let module Wm = Terrat_base_repo_config_v1.When_modified in
          match dir with
          | "lambda" ->
              Oth.Assert.true_ when_modified.Wm.autoplan;
              Oth.Assert.true_ when_modified.Wm.autoapply
          | _ -> Oth.Assert.false_ "Test Dir Config lambda JSON: unexpected value")
        changes)

let test_dir_config_module =
  Oth.test ~name:"Test Dir Config module" (fun _ ->
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:
            [
              "iam/foo.tf";
              "ec2/ec2.tf";
              "ebl/ebl.tf";
              "lambda/foo.tf";
              "ebl_modules";
              "s3/s3.tf";
              "module/foo.tf";
            ]
          dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "module/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:0 ~actual:(CCList.length changes))

let test_dir_config_null_file_patterns =
  Oth.test ~name:"Test Dir Config null_file_patterns" (fun _ ->
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:
            [
              "iam/foo.tf";
              "ec2/ec2.tf";
              "ebl/ebl.tf";
              "lambda/foo.tf";
              "ebl_modules";
              "s3/s3.tf";
              "module/foo.tf";
              "null_file_patterns/foo.tf";
            ]
          dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "null_file_patterns/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes);
      CCList.iter
        (fun {
               Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
               when_modified;
               _;
             }
           ->
          let module Wm = Terrat_base_repo_config_v1.When_modified in
          match dir with
          | "null_file_patterns" ->
              Oth.Assert.not_true when_modified.Wm.autoplan;
              Oth.Assert.true_ when_modified.Wm.autoapply
          | _ -> Oth.Assert.false_ "Test Dir Config null_file_patterns: unexpected value")
        changes)

let test_recursive_dirs_template_dir =
  Oth.test ~name:"Test Recursive Dirs Template Dir" (fun _ ->
      let file_list =
        [
          "_template/aws/terragrunt.hcl";
          "_template/aws/staging/terragrunt.hcl";
          "aws/staging/us-east-1/terragrunt.hcl";
          "aws/prod/us-east-1/terragrunt.hcl";
        ]
      in

      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "_template/*",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                       ( "aws/**/terragrunt.hcl",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn
                                                 (R.File_pattern.make "_templates/**/*.tf");
                                               CCResult.get_exn (R.File_pattern.make "${DIR}/*.hcl");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "_template/aws/terragrunt.hcl" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:0 ~actual:(CCList.length changes))

let test_recursive_dirs_aws_prod =
  Oth.test ~name:"Test Recursive Dirs AWS Prod" (fun _ ->
      let file_list =
        [
          "_template/aws/terragrunt.hcl";
          "_template/aws/staging/terragrunt.hcl";
          "aws/staging/us-east-1/terragrunt.hcl";
          "aws/prod/us-east-1/terragrunt.hcl";
        ]
      in

      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "_template/*",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                       ( "aws/**/terragrunt.hcl",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn
                                                 (R.File_pattern.make "_templates/**/*.tf");
                                               CCResult.get_exn (R.File_pattern.make "${DIR}/*.hcl");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "aws/prod/us-east-1/terragrunt.hcl" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes))

let test_recursive_dirs_tags =
  Oth.test ~name:"Test Recursive Dirs With Tags" (fun _ ->
      let file_list =
        [
          "_template/aws/terragrunt.hcl";
          "_template/aws/staging/terragrunt.hcl";
          "aws/staging/us-east-1/terragrunt.hcl";
          "aws/prod/us-east-1/terragrunt.hcl";
          "aws/prod/secrets-manager/us-east-1/terragrunt.hcl";
        ]
      in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "_template/*",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                       ( "aws/**/secrets-manager/**/terragrunt.hcl",
                         R.Dirs.Dir.make
                           ~tags:[ "secrets" ]
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn (R.File_pattern.make "${DIR}/*.hcl");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                       ( "aws/**/terragrunt.hcl",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn (R.File_pattern.make "${DIR}/*.hcl");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff =
        Terrat_change.Diff.
          [
            Add { filename = "aws/prod/us-east-1/terragrunt.hcl" };
            Add { filename = "aws/prod/secrets-manager/us-east-1/terragrunt.hcl" };
          ]
      in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes =
        CCList.filter
          (Terrat_change_match3.match_tag_query
             ~tag_query:(CCResult.get_exn (Terrat_tag_query.of_string "secrets")))
          (CCList.flatten (Terrat_change_match3.match_diff_list dirs diff))
      in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes);
      CCList.iter
        (fun {
               Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
               when_modified;
               _;
             }
           ->
          let module Wm = Terrat_base_repo_config_v1.When_modified in
          match dir with
          | "aws/prod/secrets-manager/us-east-1" ->
              Oth.Assert.true_ when_modified.Wm.autoplan;
              Oth.Assert.not_true when_modified.Wm.autoapply
          | _ -> Oth.Assert.false_ "Test Recursive Dirs With Tags: unexpected value")
        changes)

let test_recursive_dirs_without_tags =
  Oth.test ~name:"Test Recursive Dirs Without Tags" (fun _ ->
      let file_list =
        [
          "_template/aws/terragrunt.hcl";
          "_template/aws/staging/terragrunt.hcl";
          "aws/staging/us-east-1/terragrunt.hcl";
          "aws/prod/us-east-1/terragrunt.hcl";
          "aws/prod/secrets-manager/us-east-1/terragrunt.hcl";
        ]
      in

      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "_template/*",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                       ( "aws/**/secrets-manager/**/terragrunt.hcl",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn (R.File_pattern.make "${DIR}/*.hcl");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                       ( "aws/**/terragrunt.hcl",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn (R.File_pattern.make "${DIR}/*.hcl");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff =
        Terrat_change.Diff.
          [
            Add { filename = "aws/prod/us-east-1/terragrunt.hcl" };
            Add { filename = "aws/prod/secrets-manager/us-east-1/terragrunt.hcl" };
          ]
      in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      (* Both changed dirs match: aws/prod/us-east-1 (via aws/**/terragrunt.hcl) and
         aws/prod/secrets-manager/us-east-1 (also via aws/**/secrets-manager/**/...). *)
      Oth.Assert.Eq.int ~expected:2 ~actual:(CCList.length changes);
      CCList.iter
        (fun {
               Terrat_change_match3.Dirspace_config.dirspace = { Terrat_dirspace.dir; _ };
               when_modified;
               _;
             }
           ->
          let module Wm = Terrat_base_repo_config_v1.When_modified in
          match dir with
          | "aws/prod/secrets-manager/us-east-1" | "aws/prod/us-east-1" ->
              Oth.Assert.true_ when_modified.Wm.autoplan;
              Oth.Assert.not_true when_modified.Wm.autoapply
          | _ -> Oth.Assert.false_ "Test Recursive Dirs Without Tags: unexpected value")
        changes)

let test_bad_dir_config_iam =
  Oth.test ~name:"Test Bad Dir Config iam" (fun _ ->
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf"; "iam/foo.tf"; "ebl/ebl.tf"; "s3/s3.tf"; "s3/foo.tf"; "foo.tf" ]
          bad_dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "iam/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      (* matches s3 and iam *)
      Oth.Assert.Eq.int ~expected:2 ~actual:(CCList.length changes))

let test_bad_dir_config_ec2 =
  Oth.test ~name:"Test Bad Dir Config ec2" (fun _ ->
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf"; "iam/foo.tf"; "ebl/ebl.tf"; "s3/s3.tf"; "s3/foo.tf"; "foo.tf" ]
          bad_dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      (* matches s3 *)
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes))

let test_bad_dir_config_ec2_root_dir_change =
  Oth.test ~name:"Test Bad Dir Config ec2 root dir change" (fun _ ->
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf"; "iam/foo.tf"; "ebl/ebl.tf"; "s3/s3.tf"; "foo.tf" ]
          bad_dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      (* matches ., s3, and ec2 *)
      Oth.Assert.Eq.int ~expected:3 ~actual:(CCList.length changes))

let test_bad_dir_config_s3 =
  Oth.test ~name:"Test Bad Dir Config s3" (fun _ ->
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf"; "iam/foo.tf"; "ebl/ebl.tf"; "s3/s3.tf"; "s3/foo.tf"; "foo.tf" ]
          bad_dirs_config
      in
      let diff = Terrat_change.Diff.[ Add { filename = "s3/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes))

let test_module_dir_with_root_dir =
  Oth.test ~name:"Test module dir with root dir" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "foo.tf"; "module/foo/tf.tf" ]
          (R.of_view
             (R.View.make
                ~when_modified:
                  (R.When_modified.make
                     ~autoapply:true
                     ~autoplan:false
                     ~file_patterns:
                       [
                         CCResult.get_exn (R.File_pattern.make "${DIR}/*.tf");
                         CCResult.get_exn (R.File_pattern.make "${DIR}/*.tfvars");
                         CCResult.get_exn (R.File_pattern.make "${DIR}/*.json");
                       ]
                     ())
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "module",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                       ( ".",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn (R.File_pattern.make "./*.tf");
                                               CCResult.get_exn
                                                 (R.File_pattern.make "module/**/*.tf");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "module/foo.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes))

let test_large_directory_count_unmatching_files =
  Oth.test ~name:"Test large directory count unmatching files" (fun _ ->
      let num_dirs = 4000 in
      let file_list =
        "ec2/ec2.tf"
        :: CCList.flat_map
             (fun i -> CCList.map (Printf.sprintf "other/%04d/bar_%d.txt" i) (CCList.range 0 10))
             (CCList.range 0 num_dirs)
      in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive ~ctx ~index:Terrat_base_repo_config_v1.Index.empty ~file_list R.default
      in
      let diff = CCList.map (fun filename -> Terrat_change.Diff.(Change { filename })) file_list in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes))

let test_large_directory_count_matching_files =
  Oth.test ~name:"Test large directory count matching files" (fun _ ->
      (* Number of operations = num_dirs * num_files.  Its not exactly that
         because each directory is not equal amounts of work. *)
      let num_dirs = 1000 in
      let num_files_per_dir = 10 in
      let file_list =
        "ec2/ec2.tf"
        :: CCList.flat_map
             (fun i ->
               CCList.map (Printf.sprintf "tf/%04d/bar_%d.tf" i) (CCList.range 1 num_files_per_dir))
             (CCList.range 1 num_dirs)
      in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive ~ctx ~index:Terrat_base_repo_config_v1.Index.empty ~file_list R.default
      in
      let diff = CCList.map (fun filename -> Terrat_change.Diff.(Change { filename })) file_list in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Printf.printf
        "changes = %s\n%!"
        ([%show: Terrat_change_match3.Dirspace_config.t list] changes);
      Printf.printf "len(changes) = %d\n%!" (CCList.length changes);
      Oth.Assert.true_ (CCList.length changes = 1 + num_dirs))

let test_large_file_count_with_low_match_count =
  Oth.test ~name:"Test large file count with low match count" (fun _ ->
      let num_tf_dirs = 70 in
      let num_tf_files_per_dir = 10 in
      let num_dirs = 1000 in
      let num_files_per_dir = 50 in
      let file_list =
        CCList.flat_map
          (fun i ->
            CCList.map
              (Printf.sprintf "foo/terraform/%04d/foo_%d.tf" i)
              (CCList.range 1 num_tf_files_per_dir))
          (CCList.range 1 num_tf_dirs)
        @ CCList.flat_map
            (fun i ->
              CCList.map
                (Printf.sprintf "other/%04d/foo_%d.txt" i)
                (CCList.range 1 num_files_per_dir))
            (CCList.range 1 num_dirs)
      in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive ~ctx ~index:Terrat_base_repo_config_v1.Index.empty ~file_list
        @@ R.of_view
        @@ R.View.make
             ~when_modified:(R.When_modified.make ~file_patterns:[] ())
             ~dirs:(Sln_map.String.of_list [ ("**/terraform/**", R.Dirs.Dir.make ()) ])
             ()
      in
      let diff = CCList.map (fun filename -> Terrat_change.Diff.(Change { filename })) file_list in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.true_ (CCList.length changes = num_tf_dirs))

let test_large_file_count_with_low_match_count_lesser_dir_depth =
  Oth.test ~name:"Test large file count with low match count lesser dir dpeth" (fun _ ->
      (* Only meaningful difference here is our glob starts with [**] but the
         dir our terraform is in is in the root level.  Just making sure all the
         machinery works here as expected. *)
      let num_tf_dirs = 70 in
      let num_tf_files_per_dir = 10 in
      let num_dirs = 1000 in
      let num_files_per_dir = 50 in
      let file_list =
        CCList.flat_map
          (fun i ->
            CCList.map
              (Printf.sprintf "terraform/%04d/foo_%d.tf" i)
              (CCList.range 1 num_tf_files_per_dir))
          (CCList.range 1 num_tf_dirs)
        @ CCList.flat_map
            (fun i ->
              CCList.map
                (Printf.sprintf "other/%04d/foo_%d.txt" i)
                (CCList.range 1 num_files_per_dir))
            (CCList.range 1 num_dirs)
      in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive ~ctx ~index:Terrat_base_repo_config_v1.Index.empty ~file_list
        @@ R.of_view
        @@ R.View.make
             ~when_modified:(R.When_modified.make ~file_patterns:[] ())
             ~dirs:(Sln_map.String.of_list [ ("**/terraform/**", R.Dirs.Dir.make ()) ])
             ()
      in
      let diff = CCList.map (fun filename -> Terrat_change.Diff.(Change { filename })) file_list in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.true_ (CCList.length changes = num_tf_dirs))

let test_large_directory_count_non_default_when_modified =
  Oth.test ~name:"Test large directory count non default when_modified" (fun _ ->
      (* Number of operations = num_dirs * num_files.  Its not exactly that
         because each directory is not equal amounts of work. *)
      let num_dirs = 1000 in
      let num_files_per_dir = 10 in
      let file_list =
        "ec2/ec2.tf"
        :: CCList.flat_map
             (fun i ->
               CCList.map (Printf.sprintf "tf/%04d/bar_%d.tf" i) (CCList.range 1 num_files_per_dir))
             (CCList.range 1 num_dirs)
        @ [ "foo/bar.txt" ]
      in

      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~when_modified:
                  (R.When_modified.make
                     ~file_patterns:
                       [
                         CCResult.get_exn (R.File_pattern.make "**/*.bar");
                         CCResult.get_exn (R.File_pattern.make "foo/*.txt");
                       ]
                     ())
                ()))
      in
      let diff = CCList.map (fun filename -> Terrat_change.Diff.(Change { filename })) file_list in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.true_ (CCList.length changes = 2 + num_dirs))

let test_not_match =
  Oth.test ~name:"Test not match" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf" ]
          (R.of_view
             (R.View.make
                ~when_modified:
                  (R.When_modified.make
                     ~file_patterns:
                       [
                         CCResult.get_exn (R.File_pattern.make "**/*.tf");
                         CCResult.get_exn (R.File_pattern.make "!ec2/**/*.tf");
                       ]
                     ())
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:0 ~actual:(CCList.length changes))

let test_not_match_multiple =
  Oth.test ~name:"Test not match multiple" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "ec2/ec2.tf" ]
          (R.of_view
             (R.View.make
                ~when_modified:
                  (R.When_modified.make
                     ~file_patterns:
                       [
                         CCResult.get_exn (R.File_pattern.make "**/*.tf");
                         CCResult.get_exn (R.File_pattern.make "!ec2/**/*.tf");
                         CCResult.get_exn (R.File_pattern.make "!foo/*.tf");
                       ]
                     ())
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "ec2/ec2.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:0 ~actual:(CCList.length changes))

let test_relative_path_file_pattern =
  Oth.test ~name:"Test relative path file pattern" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "d/bar/foo/t.tf"; "d/bar/baz/t.tf" ]
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "d/bar/foo",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                       ( "d/**/*.tf",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn
                                                 (R.File_pattern.make "${DIR}/../foo/*.tf");
                                               CCResult.get_exn (R.File_pattern.make "${DIR}/*.tf");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "d/bar/foo/t.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes))

let test_relative_path_file_pattern_multiple_dots =
  Oth.test ~name:"Test relative path file pattern multiple dots" (fun _ ->
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list:[ "d/bar/foo/t.tf"; "d/bar/envs/baz/t.tf" ]
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "d/bar/foo",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                       ( "d/**/*.tf",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn
                                                 (R.File_pattern.make "${DIR}/../../foo/*.tf");
                                               CCResult.get_exn (R.File_pattern.make "${DIR}/*.tf");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "d/bar/foo/t.tf" } ] in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes))

let test_index_basic =
  Oth.test ~name:"Test basic index" (fun _ ->
      let module Idx = Terrat_base_repo_config_v1.Index in
      let index = Idx.make ~symlinks:[] [ ("tf", Idx.Dep.[ Module "../modules/foo" ]) ] in
      let file_list = [ "modules/foo/main.tf"; "tf/main.tf" ] in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive ~ctx ~index ~file_list R.default
      in
      let dirs = CCResult.get_exn (Terrat_change_match3.synthesize_config ~index repo_config) in
      let diff = Terrat_change.Diff.[ Add { filename = "modules/foo/main.tf" } ] in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes);
      let dirspace = (CCList.hd changes).Terrat_change_match3.Dirspace_config.dirspace in
      Oth.Assert.true_
        (Terrat_change.Dirspace.equal
           dirspace
           Terrat_change.Dirspace.{ dir = "tf"; workspace = "default" }))

let test_index_with_dirs_section =
  Oth.test ~name:"Test index with dirs section" (fun _ ->
      let module Idx = Terrat_base_repo_config_v1.Index in
      let index = Idx.make ~symlinks:[] [ ("tf", Idx.Dep.[ Module "../modules/foo" ]) ] in
      let file_list = [ "modules/foo/main.tf"; "tf/main.tf" ] in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:(Sln_map.String.of_list [ ("tf", R.Dirs.Dir.make ~tags:[ "tf" ] ()) ])
                ()))
      in
      let dirs = CCResult.get_exn (Terrat_change_match3.synthesize_config ~index repo_config) in
      let diff = Terrat_change.Diff.[ Add { filename = "modules/foo/main.tf" } ] in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes);
      let dirspace = (CCList.hd changes).Terrat_change_match3.Dirspace_config.dirspace in
      Oth.Assert.true_
        (Terrat_change.Dirspace.equal
           dirspace
           Terrat_change.Dirspace.{ dir = "tf"; workspace = "default" }))

let test_index_module_in_same_dir =
  Oth.test ~name:"Test basic index" (fun _ ->
      let module Idx = Terrat_base_repo_config_v1.Index in
      let index =
        Idx.make ~symlinks:[] [ ("tf", Idx.Dep.[ Module "./modules/foo" ]); ("tf/modules/foo", []) ]
      in
      let file_list = [ "tf/modules/foo/main.tf"; "tf/main.tf" ] in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive ~ctx ~index ~file_list R.default
      in
      let dirs = CCResult.get_exn (Terrat_change_match3.synthesize_config ~index repo_config) in
      let diff = Terrat_change.Diff.[ Add { filename = "tf/modules/foo/main.tf" } ] in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes);
      let dirspace = (CCList.hd changes).Terrat_change_match3.Dirspace_config.dirspace in
      Oth.Assert.true_
        (Terrat_change.Dirspace.equal
           dirspace
           Terrat_change.Dirspace.{ dir = "tf"; workspace = "default" }))

let test_index_symlinks =
  Oth.test ~name:"Test basic symlinks" (fun _ ->
      let module Idx = Terrat_base_repo_config_v1.Index in
      let index =
        Idx.make
          ~symlinks:[ ("tf/modules/foo", "modules/foo") ]
          [ ("tf", Idx.Dep.[ Module "./modules/foo" ]) ]
      in
      let file_list = [ "modules/foo/main.tf"; "tf/main.tf" ] in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive ~ctx ~index ~file_list R.default
      in
      let dirs = CCResult.get_exn (Terrat_change_match3.synthesize_config ~index repo_config) in
      let diff = Terrat_change.Diff.[ Add { filename = "modules/foo/main.tf" } ] in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes);
      let dirspace = (CCList.hd changes).Terrat_change_match3.Dirspace_config.dirspace in
      Oth.Assert.true_
        (Terrat_change.Dirspace.equal
           dirspace
           Terrat_change.Dirspace.{ dir = "tf"; workspace = "default" }))

let test_index_symlinks_dir_config =
  Oth.test ~name:"Test basic symlinks with dir config" (fun _ ->
      let module Idx = Terrat_base_repo_config_v1.Index in
      let index = Idx.make ~symlinks:[ ("tf/main.tf", "null/main.tf") ] [] in
      let file_list = [ "tf/main.tf"; "null/main.tf" ] in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "null",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let dirs = CCResult.get_exn (Terrat_change_match3.synthesize_config ~index repo_config) in
      let diff = Terrat_change.Diff.[ Change { filename = "null/main.tf" } ] in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes);
      let dirspace = (CCList.hd changes).Terrat_change_match3.Dirspace_config.dirspace in
      Oth.Assert.true_
        (Terrat_change.Dirspace.equal
           dirspace
           Terrat_change.Dirspace.{ dir = "tf"; workspace = "default" }))

let test_depends_on =
  Oth.test ~name:"Simple depends_on" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list = [ "base/main.tf"; "database/main.tf" ] in
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "database",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:(depends_on_q "dir:base")
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "base/main.tf" } ] in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = Terrat_change_match3.match_diff_list config diff in
      Oth.Assert.Eq.int ~expected:2 ~actual:(CCList.length changes))

let test_depends_on_multiple_depends =
  Oth.test ~name:"Simple depends_on multiple depends" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list = [ "base/main.tf"; "database1/main.tf"; "database2/main.tf" ] in
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "database1",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:(depends_on_q "dir:base")
                                           ())
                                      () );
                                ])
                           () );
                       ( "database2",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:(depends_on_q "dir:base")
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "base/main.tf" } ] in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = Terrat_change_match3.match_diff_list config diff in
      Oth.Assert.Eq.int ~expected:2 ~actual:(CCList.length changes);
      match changes with
      | [ base; databases ] ->
          Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length base);
          Oth.Assert.Eq.int ~expected:2 ~actual:(CCList.length databases)
      | _ -> Oth.Assert.false_ "Simple depends_on multiple depends: unexpected value")

let test_depends_on_multiple_depends_2 =
  Oth.test ~name:"Simple depends_on multiple depends 2" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list =
        [ "base/main.tf"; "database1/main.tf"; "database2/main.tf"; "webservice/main.tf" ]
      in
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "database1",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:(depends_on_q "dir:base")
                                           ())
                                      () );
                                ])
                           () );
                       ( "database2",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:(depends_on_q "dir:base")
                                           ())
                                      () );
                                ])
                           () );
                       ( "webservice",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:
                                             (depends_on_q "dir:database1 or dir:database2")
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "base/main.tf" } ] in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = Terrat_change_match3.match_diff_list config diff in
      Oth.Assert.Eq.int ~expected:3 ~actual:(CCList.length changes);
      match changes with
      | [ base; databases; webservice ] ->
          Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length base);
          Oth.Assert.Eq.int ~expected:2 ~actual:(CCList.length databases);
          Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length webservice)
      | _ -> Oth.Assert.false_ "Simple depends_on multiple depends 2: unexpected value")

let test_depends_on_multiple_depends_disjoint =
  Oth.test ~name:"Simple depends_on multiple depends disjoint" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list =
        [
          "base/main.tf";
          "database1/main.tf";
          "database2/main.tf";
          "webservice1/main.tf";
          "webservice2/main.tf";
        ]
      in
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "database1",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:(depends_on_q "dir:base")
                                           ())
                                      () );
                                ])
                           () );
                       ( "database2",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:(depends_on_q "dir:base")
                                           ())
                                      () );
                                ])
                           () );
                       ( "webservice1",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:(depends_on_q "dir:database1")
                                           ())
                                      () );
                                ])
                           () );
                       ( "webservice2",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:(depends_on_q "dir:database2")
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "base/main.tf" } ] in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = Terrat_change_match3.match_diff_list config diff in
      Oth.Assert.Eq.int ~expected:3 ~actual:(CCList.length changes);
      match changes with
      | [ base; databases; webservices ] ->
          Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length base);
          Oth.Assert.Eq.int ~expected:2 ~actual:(CCList.length databases);
          Oth.Assert.Eq.int ~expected:2 ~actual:(CCList.length webservices)
      | _ -> Oth.Assert.false_ "Simple depends_on multiple depends disjoint: unexpected value")

let test_depends_on_cycle =
  Oth.test ~name:"depends_on cycle error" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list = [ "base/main.tf"; "database/main.tf" ] in
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "base",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:(depends_on_q "dir:database")
                                           ())
                                      () );
                                ])
                           () );
                       ( "database",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:(depends_on_q "dir:base")
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      match
        Terrat_change_match3.synthesize_config
          ~index:Terrat_base_repo_config_v1.Index.empty
          repo_config
      with
      | Ok _ -> Oth.Assert.false_ "depends_on cycle error: unexpected value"
      | Error (`Depends_on_cycle_err _) -> ()
      | Error _ -> Oth.Assert.false_ "depends_on cycle error: unexpected value")

let test_depends_on_relative_dir =
  Oth.test ~name:"depends_on relative dir" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list =
        [
          "projects/proj1/base/main.tf";
          "projects/proj1/database/main.tf";
          "projects/proj2/base/main.tf";
          "projects/proj2/database/main.tf";
        ]
      in
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "projects/**/database/*.tf",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:(depends_on_q "relative_dir:../base")
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "projects/proj1/base/main.tf" } ] in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = Terrat_change_match3.match_diff_list config diff in
      Oth.Assert.Eq.int ~expected:2 ~actual:(CCList.length changes);
      let dirspace_eq ds { Terrat_change_match3.Dirspace_config.dirspace; _ } =
        Terrat_dirspace.equal ds dirspace
      in
      let changes = CCList.flatten changes in
      Oth.Assert.true_
        (CCOption.is_some
           (CCList.find_opt
              (dirspace_eq { Terrat_dirspace.dir = "projects/proj1/base"; workspace = "default" })
              changes));
      Oth.Assert.true_
        (CCOption.is_some
           (CCList.find_opt
              (dirspace_eq
                 { Terrat_dirspace.dir = "projects/proj1/database"; workspace = "default" })
              changes)))

let test_depends_on_prune_on_no_change_chain =
  Oth.test ~name:"depends_on prune_on_no_change chain" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list = [ "a/main.tf"; "b/main.tf"; "c/main.tf"; "d/main.tf"; "e/main.tf" ] in
      let dir tag prune =
        R.Dirs.Dir.make
          ~workspaces:
            (Sln_map.String.of_list
               [
                 ( "default",
                   R.Dirs.Workspace.make
                     ~when_modified:
                       (R.When_modified.make
                          ~depends_on:(depends_on_q ~prune_on_no_change:prune tag)
                          ())
                     () );
               ])
          ()
      in
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ("a", dir "dir:b" false);
                       ("b", dir "dir:c" false);
                       ("c", dir "dir:d" true);
                       ("d", dir "dir:e" false);
                     ])
                ()))
      in
      let diff =
        Terrat_change.Diff.[ Add { filename = "b/main.tf" }; Add { filename = "d/main.tf" } ]
      in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = Terrat_change_match3.match_diff_list config diff in
      let layer_dirs =
        CCList.map
          (CCList.map (fun { Terrat_change_match3.Dirspace_config.dirspace; _ } ->
               dirspace.Terrat_dirspace.dir))
          changes
      in
      Oth.Assert.true_
        (CCList.equal (CCList.equal CCString.equal) layer_dirs [ [ "d" ]; [ "b" ]; [ "a" ] ]))

let test_depends_on_prune_on_no_change_all_pruned =
  Oth.test ~name:"depends_on prune_on_no_change all pruned" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list = [ "a/main.tf"; "b/main.tf"; "c/main.tf" ] in
      let dir tag =
        R.Dirs.Dir.make
          ~workspaces:
            (Sln_map.String.of_list
               [
                 ( "default",
                   R.Dirs.Workspace.make
                     ~when_modified:
                       (R.When_modified.make
                          ~depends_on:(depends_on_q ~prune_on_no_change:true tag)
                          ())
                     () );
               ])
          ()
      in
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:(Sln_map.String.of_list [ ("a", dir "dir:b"); ("b", dir "dir:c") ])
                ()))
      in
      let diff = Terrat_change.Diff.[ Add { filename = "c/main.tf" } ] in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = Terrat_change_match3.match_diff_list config diff in
      let layer_dirs =
        CCList.map
          (CCList.map (fun { Terrat_change_match3.Dirspace_config.dirspace; _ } ->
               dirspace.Terrat_dirspace.dir))
          changes
      in
      Oth.Assert.true_ (CCList.equal (CCList.equal CCString.equal) layer_dirs [ [ "c" ] ]))

(* A dirspace belongs in the earliest layer its dependencies allow.

   Configuration here:

     a  depends_on  dir:b
     b  depends_on  dir:c
     c  depends_on  nothing
     d  depends_on  nothing, and nothing depends on d

   [c] and [d] are both changed, so [b] and [a] come in as dependents.  [d] is
   isolated: it has no dependency and no dependent, so [d] runs in layer 0
   alongside [c], and the layering is [[c; d]; [b]; [a]].

   This is a regression test for a defect in the layer assignment that
   [Terrat_change_match3.sort] used before it moved to Kahn's algorithm.  The
   old code took a topological order from Tsort and scanned it left to right,
   opening a new layer at each direct-dependency conflict.  Tsort emits every
   node with no dependent first, and [sort] reversed that list, so an isolated
   node like [d] always landed at the END of the order, where a left-to-right
   scan can no longer put it in layer 0.  It produced [[c]; [b; d]; [a]].  Which
   later layer [d] joined depended on the hash order Tsort returned -- over 650
   name permutations of this shape, [d] landed with [b] about half the time and
   with [a] the other half, and in layer 0 never. *)
let test_layer_is_earliest_possible =
  Oth.test ~name:"layer is the earliest possible" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list = [ "a/main.tf"; "b/main.tf"; "c/main.tf"; "d/main.tf" ] in
      let dir_depends_on tag =
        R.Dirs.Dir.make
          ~workspaces:
            (Sln_map.String.of_list
               [
                 ( "default",
                   R.Dirs.Workspace.make
                     ~when_modified:(R.When_modified.make ~depends_on:(depends_on_q tag) ())
                     () );
               ])
          ()
      in
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ("a", dir_depends_on "dir:b");
                       ("b", dir_depends_on "dir:c");
                       ("c", R.Dirs.Dir.make ());
                       ("d", R.Dirs.Dir.make ());
                     ])
                ()))
      in
      let diff =
        Terrat_change.Diff.[ Change { filename = "c/main.tf" }; Change { filename = "d/main.tf" } ]
      in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = Terrat_change_match3.match_diff_list config diff in
      let layer_dirs =
        CCList.map
          (fun layer ->
            CCList.sort CCString.compare
            @@ CCList.map
                 (fun { Terrat_change_match3.Dirspace_config.dirspace; _ } ->
                   dirspace.Terrat_dirspace.dir)
                 layer)
          changes
      in
      (* [d] has no dependency, so [d] belongs in the first layer.  This
         assertion does not depend on the hash order Tsort returns. *)
      Oth.Assert.true_
        (CCList.mem
           ~eq:CCString.equal
           "d"
           (CCOption.get_or ~default:[] (CCList.head_opt layer_dirs)));
      (* The whole layering, stated as it should be. *)
      Oth.Assert.true_
        (CCList.equal (CCList.equal CCString.equal) layer_dirs [ [ "c"; "d" ]; [ "b" ]; [ "a" ] ]);
      ())

(* The same rule as [test_layer_is_earliest_possible], but here [a] depends on
   the isolated dirspace.  See that test for the defect this guards against.

   Configuration here:

     a  depends_on  dir:b or dir:h
     b  depends_on  dir:c
     c  depends_on  nothing
     h  depends_on  nothing

   [c] and [h] are changed, so [b] and [a] come in as dependents.  [h] depends
   on nothing, so [h] runs in layer 0 and the layering is [[c; h]; [b]; [a]].

   The directory name [h] is load bearing, so do not rename it.  [b] and [h]
   have the same single dependent, [a], so the old Tsort-based code made them
   ready in the same round and returned them in hash order, and whichever the
   scan reached first opened the layer.  Over 676 name permutations of this
   shape, 308 put [h] in [b]'s layer and the rest happened to put it in layer 0
   -- correct by luck, not by construction.  [h] is one of the names that showed
   the defect, which is why the fixture uses it. *)
let test_layer_is_earliest_possible_shared_dependent =
  Oth.test ~name:"layer is the earliest possible with a shared dependent" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list = [ "a/main.tf"; "b/main.tf"; "c/main.tf"; "h/main.tf" ] in
      let dir_depends_on tag =
        R.Dirs.Dir.make
          ~workspaces:
            (Sln_map.String.of_list
               [
                 ( "default",
                   R.Dirs.Workspace.make
                     ~when_modified:(R.When_modified.make ~depends_on:(depends_on_q tag) ())
                     () );
               ])
          ()
      in
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ("a", dir_depends_on "dir:b or dir:h");
                       ("b", dir_depends_on "dir:c");
                       ("c", R.Dirs.Dir.make ());
                       ("h", R.Dirs.Dir.make ());
                     ])
                ()))
      in
      let diff =
        Terrat_change.Diff.[ Change { filename = "c/main.tf" }; Change { filename = "h/main.tf" } ]
      in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = Terrat_change_match3.match_diff_list config diff in
      let layer_dirs =
        CCList.map
          (fun layer ->
            CCList.sort CCString.compare
            @@ CCList.map
                 (fun { Terrat_change_match3.Dirspace_config.dirspace; _ } ->
                   dirspace.Terrat_dirspace.dir)
                 layer)
          changes
      in
      Oth.Assert.true_
        (CCList.mem
           ~eq:CCString.equal
           "h"
           (CCOption.get_or ~default:[] (CCList.head_opt layer_dirs)));
      Oth.Assert.true_
        (CCList.equal (CCList.equal CCString.equal) layer_dirs [ [ "c"; "h" ]; [ "b" ]; [ "a" ] ]);
      ())

(* [Terrat_change_match3.collect_dependents] must walk each dirspace
   one time, not each path to it.

   The fixture is a chain of diamonds: level [i] holds two directories, and each
   of them declares [depends_on] against BOTH directories of level [i - 1].
   Only one directory of level 0 changes.  The number of paths from it doubles
   at every level, so a collector with no visited set costs time exponential in
   the depth while the dirspace count grows by two.  At 24 levels -- 47
   dirspaces -- that was about 31 seconds, against about a millisecond with the
   visited set.

   The test asserts the layering and a CPU time bound.  The bound is what makes
   a regression fail rather than appear as a slow suite.  It is 3 seconds: ten
   times under the cost of the defect and three thousand times over the cost of
   the correct code, so neither a fast nor a slow machine changes the verdict.
   [Oth.timeout] would say this better, but it is [nyi] in the sync backend. *)
let test_collect_dependents_visits_each_dirspace_once =
  Oth.test ~name:"collect dependents visits each dirspace one time" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let levels = 2000 in
      let name i j = Printf.sprintf "l%02dw%d" i j in
      let dir i =
        if i = 0 then R.Dirs.Dir.make ()
        else
          R.Dirs.Dir.make
            ~workspaces:
              (Sln_map.String.of_list
                 [
                   ( "default",
                     R.Dirs.Workspace.make
                       ~when_modified:
                         (R.When_modified.make
                            ~depends_on:
                              (depends_on_q
                                 (Printf.sprintf
                                    "dir:%s or dir:%s"
                                    (name (i - 1) 0)
                                    (name (i - 1) 1)))
                            ())
                       () );
                 ])
            ()
      in
      let dirs =
        CCList.flat_map
          (fun i -> CCList.map (fun j -> (name i j, dir i)) [ 0; 1 ])
          (CCList.range' 0 levels)
      in
      let file_list = CCList.map (fun (n, _) -> n ^ "/main.tf") dirs in
      let repo_config =
        derive
          ~ctx
          ~index:R.Index.empty
          ~file_list
          (R.of_view (R.View.make ~dirs:(Sln_map.String.of_list dirs) ()))
      in
      let config =
        CCResult.get_exn (Terrat_change_match3.synthesize_config ~index:R.Index.empty repo_config)
      in
      let diff = Terrat_change.Diff.[ Change { filename = name 0 0 ^ "/main.tf" } ] in
      let start = Sys.time () in
      let changes = Terrat_change_match3.match_diff_list config diff in
      let elapsed = Sys.time () -. start in
      (* One changed directory in layer 0, then two per level after it. *)
      Oth.Assert.Eq.int ~expected:levels ~actual:(CCList.length changes);
      Oth.Assert.Eq.int
        ~expected:(1 + (2 * (levels - 1)))
        ~actual:(CCList.length (CCList.flatten changes));
      Oth.Assert.true_ (elapsed < 3.0);
      ())

(* A dirspace that [modified_by] brings into a run must itself bring in the
   dirspaces that declare [depends_on] against it.

   Configuration here:

     base   stack base
     other  stack other
     app    stack app, modified_by [base], plan_after [other]
     db     depends_on dir:app

   Only [base] changes.  [app] is in stack [app], which is modified_by [base],
   so [app] runs.  [db] declares [depends_on] against [app], so [db] runs too.

   The explicit [plan_after] is what makes this the interesting case.  A stack
   that names [modified_by] and no [plan_after] gets [plan_after] from
   [modified_by] when the configuration is decoded, which puts an edge in the
   topology.  Naming [plan_after] keeps that edge away, so nothing in the
   topology joins [base] to [app], and [app] can only arrive through the
   [modified_by] lookup.  The collector used to follow the two relations one
   after the other, so a dirspace that arrived by [modified_by] was never
   expanded again and [db] was lost. *)
let test_modified_by_pull_collects_depends_on =
  Oth.test ~name:"a modified_by pull collects its depends_on dependents" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list = [ "base/main.tf"; "other/main.tf"; "app/main.tf"; "db/main.tf" ] in
      let stack ?rules name =
        R.Stacks.Stack.make
          ~type_:
            (R.Stacks.Type_.Stack (CCResult.get_exn (Terrat_tag_query.of_string ("dir:" ^ name))))
          ?rules
          ()
      in
      let repo_config =
        derive
          ~ctx
          ~index:R.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ("base", R.Dirs.Dir.make ());
                       ("other", R.Dirs.Dir.make ());
                       ("app", R.Dirs.Dir.make ());
                       ( "db",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:(depends_on_q "dir:app")
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ~stacks:
                  (R.Stacks.make
                     ~names:
                       (Sln_map.String.of_list
                          [
                            (* [db] declares [depends_on] against [app], which is
                               another stack.  A [depends_on] may only cross a
                               stack boundary inside a nested stack, so one holds
                               all four. *)
                            ( "all",
                              R.Stacks.Stack.make
                                ~type_:(R.Stacks.Type_.Nested [ "base"; "other"; "db"; "app" ])
                                () );
                            ("base", stack "base");
                            ("other", stack "other");
                            ("db", stack "db");
                            ( "app",
                              stack
                                ~rules:
                                  (R.Stacks.Rules.make
                                     ~modified_by:[ "base" ]
                                     ~plan_after:[ "other" ]
                                     ())
                                "app" );
                          ])
                     ())
                ()))
      in
      let diff = Terrat_change.Diff.[ Change { filename = "base/main.tf" } ] in
      let config =
        CCResult.get_exn (Terrat_change_match3.synthesize_config ~index:R.Index.empty repo_config)
      in
      let layer_dirs =
        CCList.map
          (fun layer ->
            CCList.sort CCString.compare
            @@ CCList.map
                 (fun { Terrat_change_match3.Dirspace_config.dirspace; _ } ->
                   dirspace.Terrat_dirspace.dir)
                 layer)
          (Terrat_change_match3.match_diff_list config diff)
      in
      Oth.Assert.true_
        (CCList.equal (CCList.equal CCString.equal) layer_dirs [ [ "app"; "base" ]; [ "db" ] ]);
      ())

(* [modified_by] may name a cycle.  [assert_no_stack_cycle] covers nested
   stacks, [plan_after] and [apply_after], but not [modified_by], so
   [synthesize_config] accepts stack [a] modified_by [b] and stack [b]
   modified_by [a].  The collector must end on its own.  Both dirspaces run,
   and neither declares an order over the other, so both are in one layer. *)
let test_modified_by_cycle_terminates =
  Oth.test ~name:"a modified_by cycle terminates" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list = [ "a/main.tf"; "b/main.tf" ] in
      let stack name modified_by =
        R.Stacks.Stack.make
          ~type_:
            (R.Stacks.Type_.Stack (CCResult.get_exn (Terrat_tag_query.of_string ("dir:" ^ name))))
          ~rules:(R.Stacks.Rules.make ~modified_by ())
          ()
      in
      let repo_config =
        derive
          ~ctx
          ~index:R.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list [ ("a", R.Dirs.Dir.make ()); ("b", R.Dirs.Dir.make ()) ])
                ~stacks:
                  (R.Stacks.make
                     ~names:
                       (Sln_map.String.of_list
                          [ ("a", stack "a" [ "b" ]); ("b", stack "b" [ "a" ]) ])
                     ())
                ()))
      in
      let diff = Terrat_change.Diff.[ Change { filename = "a/main.tf" } ] in
      let config =
        CCResult.get_exn (Terrat_change_match3.synthesize_config ~index:R.Index.empty repo_config)
      in
      let layer_dirs =
        CCList.map
          (fun layer ->
            CCList.sort CCString.compare
            @@ CCList.map
                 (fun { Terrat_change_match3.Dirspace_config.dirspace; _ } ->
                   dirspace.Terrat_dirspace.dir)
                 layer)
          (Terrat_change_match3.match_diff_list config diff)
      in
      Oth.Assert.true_ (CCList.equal (CCList.equal CCString.equal) layer_dirs [ [ "a"; "b" ] ]);
      ())

let test_force_matches_not_pruned =
  Oth.test ~name:"force_matches not pruned" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list = [ "a/main.tf"; "b/main.tf" ] in
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "a",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:
                                             (depends_on_q ~prune_on_no_change:true "dir:b")
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let force =
        CCOption.get_exn_or
          "force-match"
          (Terrat_change_match3.of_dirspace
             config
             { Terrat_dirspace.dir = "a"; workspace = "default" })
      in
      let changes = Terrat_change_match3.match_diff_list ~force_matches:[ force ] config [] in
      let layer_dirs =
        CCList.map
          (CCList.map (fun { Terrat_change_match3.Dirspace_config.dirspace; _ } ->
               dirspace.Terrat_dirspace.dir))
          changes
      in
      Oth.Assert.true_ (CCList.equal (CCList.equal CCString.equal) layer_dirs [ [ "a" ] ]))

let test_files_in_same_dir_match_multiple_dirs =
  Oth.test ~name:"files_in_same_dir_match_multiple_dirs" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let file_list = [ "projects/dir1/file1"; "projects/dir1/file2" ] in
      let repo_config =
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "projects/**",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                       ( "projects/**/file1",
                         R.Dirs.Dir.make
                           ~tags:[ "dir1" ]
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [ CCResult.get_exn (R.File_pattern.make "${DIR}/*") ]
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      let diff =
        Terrat_change.Diff.
          [ Add { filename = "projects/dir1/file1" }; Add { filename = "projects/dir1/file2" } ]
      in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list config diff) in
      Oth.Assert.Eq.int ~expected:1 ~actual:(CCList.length changes);
      match changes with
      | [ { Terrat_change_match3.Dirspace_config.tags; _ } ] ->
          Oth.Assert.true_ (Terrat_tag_set.mem "dir1" tags)
      | _ -> Oth.Assert.false_ "files_in_same_dir_match_multiple_dirs: unexpected value")

(* This test is for timing and the numbers of been reduced in this to make it
   run quickly, increase the numbers, as described, to test various directory
   size configurations. *)
let test_large_directory_timing =
  Oth.test ~name:"Test large directory timing" (fun _ ->
      (* Set to 2000 and 7000 respectivively to see some mean performance issues *)
      let num_tf_dirs = 20 in
      let num_other_dirs = 70 in
      let tf_files =
        CCList.flat_map (fun i ->
            CCList.map (fun j -> Printf.sprintf "this_is_terraform_code_%d/tf_%d.tf" i j)
            @@ CCList.range 1 10)
        @@ CCList.range 1 num_tf_dirs
      in
      let other_files =
        CCList.flat_map (fun i ->
            CCList.map (fun j -> Printf.sprintf "this_is_not_terraform_code_%d/foo_%d.txt" i j)
            @@ CCList.range 1 10)
        @@ CCList.range 1 num_other_dirs
      in
      let file_list = tf_files @ other_files in
      let repo_config =
        let module R = Terrat_base_repo_config_v1 in
        derive
          ~ctx
          ~index:Terrat_base_repo_config_v1.Index.empty
          ~file_list
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "this_is_not_terraform_code_*/*",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:(R.When_modified.make ~file_patterns:[] ())
                                      () );
                                ])
                           () );
                       ( "this_is_terraform_code_*/*.tf",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~file_patterns:
                                             [
                                               CCResult.get_exn (R.File_pattern.make "${DIR}/*.tf");
                                               CCResult.get_exn
                                                 (R.File_pattern.make "${DIR}/*.tfvars");
                                               CCResult.get_exn
                                                 (R.File_pattern.make "${DIR}/*.json");
                                               CCResult.get_exn
                                                 (R.File_pattern.make "terraform/modules/**/*.tf");
                                             ]
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ()))
      in
      (* Printf.printf *)
      (*   "%s\n%!" *)
      (*   Terrat_base_repo_config_v1.( *)
      (*     Yojson.Safe.pretty_to_string @@ View.to_yojson @@ to_view repo_config); *)
      let diff = CCList.map (fun filename -> Terrat_change.Diff.(Change { filename })) file_list in
      let dirs =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config
             ~index:Terrat_base_repo_config_v1.Index.empty
             repo_config)
      in
      let changes = CCList.flatten (Terrat_change_match3.match_diff_list dirs diff) in
      Oth.Assert.true_ (CCList.length changes = num_tf_dirs))

(* The layer function, run over a subset of a run.  [layers_of] answers "what
   can run now, and how many rounds are left" for the dirspaces that remain, so
   the three tests below pin what a dirspace outside the subset does to the
   order.

   The chain is [a] depends_on [b] depends_on [c] in every one of them. *)
let layers_of_chain_config () =
  let module R = Terrat_base_repo_config_v1 in
  let dir_depends_on tag =
    R.Dirs.Dir.make
      ~workspaces:
        (Sln_map.String.of_list
           [
             ( "default",
               R.Dirs.Workspace.make
                 ~when_modified:(R.When_modified.make ~depends_on:(depends_on_q tag) ())
                 () );
           ])
      ()
  in
  let repo_config =
    derive
      ~ctx
      ~index:R.Index.empty
      ~file_list:[ "a/main.tf"; "b/main.tf"; "c/main.tf" ]
      (R.of_view
         (R.View.make
            ~dirs:
              (Sln_map.String.of_list
                 [
                   ("a", dir_depends_on "dir:b");
                   ("b", dir_depends_on "dir:c");
                   ("c", R.Dirs.Dir.make ());
                 ])
            ()))
  in
  CCResult.get_exn (Terrat_change_match3.synthesize_config ~index:R.Index.empty repo_config)

(* The directory of every dirspace, layer by layer, sorted inside each layer so
   the assertion does not depend on the order the sort happens to return. *)
let dirs_of_layers layers =
  CCList.map
    (fun layer ->
      CCList.sort CCString.compare
      @@ CCList.map
           (fun {
                  Terrat_change_match3.Dirspace_config.dirspace;
                  file_pattern_matcher = _;
                  lock_branch_target = _;
                  stack_config = _;
                  stack_name = _;
                  stack_paths = _;
                  tags = _;
                  when_modified = _;
                }
              -> dirspace.Terrat_dirspace.dir)
           layer)
    layers

(* Every dirspace of a run, with the layer boundaries thrown away. *)
let flatten_matches config diff = CCList.flatten (Terrat_change_match3.match_diff_list config diff)

let dirspace_configs_of_dirs config dirs =
  CCList.map
    (fun dir ->
      CCOption.get_exn_or ("no such dirspace: " ^ dir)
      @@ Terrat_change_match3.of_dirspace config { Terrat_dirspace.dir; workspace = "default" })
    dirs

let test_layers_of_dependency_outside_subset =
  Oth.test ~name:"layers_of: a dependency outside the subset does not delay" (fun _ ->
      let config = layers_of_chain_config () in
      (* [c] has been applied and is gone from the subset.  [b] depended only on
         [c], so nothing holds [b] back any more. *)
      let layers =
        dirs_of_layers
        @@ Terrat_change_match3.layers_of config (dirspace_configs_of_dirs config [ "b"; "a" ])
      in
      Oth.Assert.true_
        ~fail_msg:"layers = [ [ \"b\" ]; [ \"a\" ] ]"
        (CCList.equal (CCList.equal CCString.equal) layers [ [ "b" ]; [ "a" ] ]);
      ())

let test_layers_of_dependency_inside_subset =
  Oth.test ~name:"layers_of: a dependency inside the subset delays" (fun _ ->
      let config = layers_of_chain_config () in
      let layers =
        dirs_of_layers
        @@ Terrat_change_match3.layers_of config (dirspace_configs_of_dirs config [ "c"; "b"; "a" ])
      in
      (* The number of layers is the depth of the subset. *)
      Oth.Assert.true_
        ~fail_msg:"layers = [ [ \"c\" ]; [ \"b\" ]; [ \"a\" ] ]"
        (CCList.equal (CCList.equal CCString.equal) layers [ [ "c" ]; [ "b" ]; [ "a" ] ]);
      ())

(* The case a direct-edge rule gets wrong.  [b] is not in the subset, and the
   only path from [c] to [a] runs through it.  [b] cannot delay anything, but
   [a] still depends on [c] through it, so [a] must not join [c] in the first
   layer.

   This is the shape of the [prune_on_no_change] fixture
   [core/layered_runs/0012]: [match_diff_list] prunes [b] after it has sorted,
   so the run that reaches the evaluator is exactly [c] and [a]. *)
let test_layers_of_contracts_through_a_missing_dirspace =
  Oth.test ~name:"layers_of: the order survives a dirspace that is not in the subset" (fun _ ->
      let config = layers_of_chain_config () in
      let layers =
        dirs_of_layers
        @@ Terrat_change_match3.layers_of config (dirspace_configs_of_dirs config [ "c"; "a" ])
      in
      Oth.Assert.true_
        ~fail_msg:"layers = [ [ \"c\" ]; [ \"a\" ] ]"
        (CCList.equal (CCList.equal CCString.equal) layers [ [ "c" ]; [ "a" ] ]);
      ())

(* Two environments, [dev] and [prod], each [networking -> database -> app] by
   [depends_on], one stack for each environment, and [apply_after: [dev]] on
   [prod].  This is the [core/stacks/0027] fixture.  [cross_env_depends_on]
   makes [dev/database] depend on [prod/networking] instead, which crosses the
   stack boundary. *)
let two_environment_config
    ?(cross_env_depends_on = false)
    ?(nested = false)
    ?(apply_after = true)
    () =
  let module R = Terrat_base_repo_config_v1 in
  let dir ~env ?depends_on () =
    R.Dirs.Dir.make
      ~workspaces:
        (Sln_map.String.of_list
           [
             ( "default",
               R.Dirs.Workspace.make
                 ~tags:[ env ]
                 ~when_modified:
                   (R.When_modified.make ?depends_on:(CCOption.map depends_on_q depends_on) ())
                 () );
           ])
      ()
  in
  let stack ?rules tag =
    R.Stacks.Stack.make
      ~type_:(R.Stacks.Type_.Stack (CCResult.get_exn (Terrat_tag_query.of_string tag)))
      ?rules
      ()
  in
  let dev_database_depends_on =
    if cross_env_depends_on then "dir:prod/networking" else "dir:dev/networking"
  in
  derive
    ~ctx
    ~index:R.Index.empty
    ~file_list:
      [
        "dev/networking/main.tf";
        "dev/database/main.tf";
        "dev/app/main.tf";
        "prod/networking/main.tf";
        "prod/database/main.tf";
        "prod/app/main.tf";
      ]
    (R.of_view
       (R.View.make
          ~dirs:
            (Sln_map.String.of_list
               [
                 ("dev/networking", dir ~env:"dev" ());
                 ("dev/database", dir ~env:"dev" ~depends_on:dev_database_depends_on ());
                 ("dev/app", dir ~env:"dev" ~depends_on:"dir:dev/database" ());
                 ("prod/networking", dir ~env:"prod" ());
                 ("prod/database", dir ~env:"prod" ~depends_on:"dir:prod/networking" ());
                 ("prod/app", dir ~env:"prod" ~depends_on:"dir:prod/database" ());
               ])
          ~stacks:
            (R.Stacks.make
               ~names:
                 (Sln_map.String.of_list
                    ((if nested then
                        [
                          ( "all",
                            R.Stacks.Stack.make ~type_:(R.Stacks.Type_.Nested [ "dev"; "prod" ]) ()
                          );
                        ]
                      else [])
                    @ [
                        ("dev", stack "dev");
                        ( "prod",
                          stack
                            ~rules:
                              (R.Stacks.Rules.make
                                 ~apply_after:(if apply_after then [ "dev" ] else [])
                                 ())
                            "prod" );
                      ]))
               ())
          ()))

let two_environment_networking_diff =
  Terrat_change.Diff.
    [
      Change { filename = "dev/networking/main.tf" };
      Change { filename = "prod/networking/main.tf" };
    ]

(* [apply_after] adds no plan edge, so the two environments interleave in the
   plan layering and the run looks three rounds long.  It really takes six,
   because no [prod] dirspace may apply while a [dev] one is unapplied.  That is
   the number the comment has to show, and it is what [apply_layers_of] is
   for. *)
let test_apply_layers_of_counts_apply_after =
  Oth.test ~name:"apply_layers_of: apply_after is a round, plan layering is not" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config ~index:R.Index.empty (two_environment_config ()))
      in
      let matches = flatten_matches config two_environment_networking_diff in
      let plan_layers =
        dirs_of_layers
        @@ Terrat_change_match3.match_diff_list config two_environment_networking_diff
      in
      Oth.Assert.true_
        ~fail_msg:"the plan layering interleaves the environments"
        (CCList.equal
           (CCList.equal CCString.equal)
           plan_layers
           [
             [ "dev/networking"; "prod/networking" ];
             [ "dev/database"; "prod/database" ];
             [ "dev/app"; "prod/app" ];
           ]);
      Oth.Assert.true_
        ~fail_msg:"the apply layering is one dirspace per round"
        (CCList.equal
           (CCList.equal CCString.equal)
           (dirs_of_layers @@ Terrat_change_match3.apply_layers_of config matches)
           [
             [ "dev/networking" ];
             [ "dev/database" ];
             [ "dev/app" ];
             [ "prod/networking" ];
             [ "prod/database" ];
             [ "prod/app" ];
           ]);
      ())

(* After [dev/networking] applies, [dev/database] is free because its only
   dependency is applied, and [prod/networking] is free because [apply_after] is
   not a plan edge.  They plan together.  This is the step the run used to stop
   at. *)
let test_layers_of_frees_a_branch_after_an_apply =
  Oth.test ~name:"layers_of: an applied dependency frees its dependent" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let config =
        CCResult.get_exn
          (Terrat_change_match3.synthesize_config ~index:R.Index.empty (two_environment_config ()))
      in
      let remaining =
        CCList.filter
          (fun {
                 Terrat_change_match3.Dirspace_config.dirspace;
                 file_pattern_matcher = _;
                 lock_branch_target = _;
                 stack_config = _;
                 stack_name = _;
                 stack_paths = _;
                 tags = _;
                 when_modified = _;
               }
             -> not (CCString.equal "dev/networking" dirspace.Terrat_dirspace.dir))
          (flatten_matches config two_environment_networking_diff)
      in
      let layers = dirs_of_layers @@ Terrat_change_match3.layers_of config remaining in
      Oth.Assert.true_
        ~fail_msg:"the first layer is dev/database and prod/networking"
        (CCList.equal
           CCString.equal
           (CCOption.get_or ~default:[] (CCList.head_opt layers))
           [ "dev/database"; "prod/networking" ]);
      ())

(* [depends_on] gives the order inside one stack.  Reaching out of the stack is
   an error, the same way a stack rule that names a stack that does not exist is
   an error.  The message has to name both directories and both stacks, because
   neither half tells the user which configuration to change. *)
let test_depends_on_crossing_a_stack_boundary =
  Oth.test ~name:"depends_on across two stacks is an error" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      match
        Terrat_change_match3.synthesize_config
          ~index:R.Index.empty
          (two_environment_config ~cross_env_depends_on:true ~apply_after:false ())
      with
      | Ok _ -> Oth.Assert.false_ "depends_on across two stacks: expected an error"
      | Error
          (`Depends_on_crosses_stack_err
             {
               Terrat_change_match3.Stack_boundary.dependent =
                 { Terrat_dirspace.dir = dep_dir; workspace = _ };
               dependent_stack;
               dependency = { Terrat_dirspace.dir = dependency_dir; workspace = _ };
               dependency_stack;
             }) ->
          Oth.Assert.Eq.string ~expected:"dev/database" ~actual:dep_dir;
          Oth.Assert.Eq.string ~expected:"dev" ~actual:dependent_stack;
          Oth.Assert.Eq.string ~expected:"prod/networking" ~actual:dependency_dir;
          Oth.Assert.Eq.string ~expected:"prod" ~actual:dependency_stack;
          ()
      | Error _ -> Oth.Assert.false_ "depends_on across two stacks: unexpected error")

(* The same [depends_on], with both stacks nested under one.  They now have a
   stack in common, so the dependency stays inside it and the configuration is
   good. *)
let test_depends_on_inside_a_nested_stack =
  Oth.test ~name:"depends_on across two stacks of one nested stack is fine" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      match
        Terrat_change_match3.synthesize_config
          ~index:R.Index.empty
          (two_environment_config ~cross_env_depends_on:true ~nested:true ~apply_after:false ())
      with
      | Ok _ -> ()
      | Error err ->
          Oth.Assert.false_
            ("nested stacks: unexpected error: "
            ^ Terrat_change_match3.show_synthesize_config_err err))

(* A stack rule that orders the same pair does not excuse the [depends_on].  The
   two are separate configuration mistakes and the user has to be told about the
   one they wrote. *)
let test_depends_on_crossing_a_boundary_a_stack_rule_also_orders =
  Oth.test ~name:"a stack rule does not excuse a depends_on across a boundary" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let repo_config =
        derive
          ~ctx
          ~index:R.Index.empty
          ~file_list:[ "d1/main.tf"; "d2/main.tf" ]
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ( "d1",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:(depends_on_q "dir:d2")
                                           ())
                                      () );
                                ])
                           () );
                       ("d2", R.Dirs.Dir.make ());
                     ])
                ~stacks:
                  (R.Stacks.make
                     ~names:
                       (Sln_map.String.of_list
                          [
                            ( "x",
                              R.Stacks.Stack.make
                                ~type_:
                                  (R.Stacks.Type_.Stack
                                     (CCResult.get_exn (Terrat_tag_query.of_string "dir:d1")))
                                ~rules:(R.Stacks.Rules.make ~plan_after:[ "y" ] ())
                                () );
                            ( "y",
                              R.Stacks.Stack.make
                                ~type_:
                                  (R.Stacks.Type_.Stack
                                     (CCResult.get_exn (Terrat_tag_query.of_string "dir:d2")))
                                () );
                          ])
                     ())
                ()))
      in
      match Terrat_change_match3.synthesize_config ~index:R.Index.empty repo_config with
      | Ok _ -> Oth.Assert.false_ "a stack rule hid the boundary crossing"
      | Error (`Depends_on_crosses_stack_err _) -> ()
      | Error _ -> Oth.Assert.false_ "unexpected error")

(* A cycle can still mix a [depends_on] with a stack rule, as long as both ends
   are in one nested stack.  [d1] waits for [d2] because its stack says
   [plan_after: [y]], and [d2] waits for [d1] because of its own [depends_on].
   The message has to say which rule made which edge -- the two configuration
   sections are far apart in the file and the dirspace names alone do not say
   where to look. *)
let test_depends_on_cycle_names_the_rule =
  Oth.test ~name:"the cycle message names the rule of each edge" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let stack ?rules dir =
        R.Stacks.Stack.make
          ~type_:
            (R.Stacks.Type_.Stack (CCResult.get_exn (Terrat_tag_query.of_string ("dir:" ^ dir))))
          ?rules
          ()
      in
      let repo_config =
        derive
          ~ctx
          ~index:R.Index.empty
          ~file_list:[ "d1/main.tf"; "d2/main.tf" ]
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ("d1", R.Dirs.Dir.make ());
                       ( "d2",
                         R.Dirs.Dir.make
                           ~workspaces:
                             (Sln_map.String.of_list
                                [
                                  ( "default",
                                    R.Dirs.Workspace.make
                                      ~when_modified:
                                        (R.When_modified.make
                                           ~depends_on:(depends_on_q "dir:d1")
                                           ())
                                      () );
                                ])
                           () );
                     ])
                ~stacks:
                  (R.Stacks.make
                     ~names:
                       (Sln_map.String.of_list
                          [
                            ( "all",
                              R.Stacks.Stack.make ~type_:(R.Stacks.Type_.Nested [ "x"; "y" ]) () );
                            ("x", stack ~rules:(R.Stacks.Rules.make ~plan_after:[ "y" ] ()) "d1");
                            ("y", stack "d2");
                          ])
                     ())
                ()))
      in
      match Terrat_change_match3.synthesize_config ~index:R.Index.empty repo_config with
      | Ok _ -> Oth.Assert.false_ "expected a cycle"
      | Error (`Depends_on_cycle_err edges) ->
          let named =
            CCList.sort CCString.compare
            @@ CCList.map
                 (fun {
                        Terrat_change_match3.Dependency_edge.dependent =
                          { Terrat_dirspace.dir = dependent; workspace = _ };
                        dependency = { Terrat_dirspace.dir = dependency; workspace = _ };
                        rule;
                      }
                    -> dependent ^ " waits for " ^ dependency ^ " by " ^ rule)
                 edges
          in
          Oth.Assert.true_
            ~fail_msg:("cycle edges = " ^ CCString.concat ", " named)
            (CCList.equal
               CCString.equal
               named
               [ "d1 waits for d2 by plan_after"; "d2 waits for d1 by depends_on" ]);
          ()
      | Error _ -> Oth.Assert.false_ "unexpected error")

(* Contraction must not invent an order that the run did not already have.

   A stack rule never pulls a dirspace into a run -- [collect_dependents]
   follows [depends_on] and [modified_by] only -- so a stack in the middle of a
   [plan_after] chain can be empty while the stacks on both sides of it run.
   Contraction walks through that empty stack.  It adds nothing, because
   [collect_deps] closes [plan_after] transitively when the configuration is
   synthesized, so [sc] already lists [sa] and the edge is a direct one.

   The assertion is that the two layerings agree.  If they ever stop agreeing,
   [match_diff_list] and [layers_of] disagree about the same dirspaces, and the
   first layer of a run would depend on which of them computed it. *)
let test_layers_of_agrees_with_match_diff_list_through_an_empty_stack =
  Oth.test ~name:"layers_of: an empty stack in a plan_after chain adds no order" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let stack ?rules dir =
        R.Stacks.Stack.make
          ~type_:
            (R.Stacks.Type_.Stack (CCResult.get_exn (Terrat_tag_query.of_string ("dir:" ^ dir))))
          ?rules
          ()
      in
      let repo_config =
        derive
          ~ctx
          ~index:R.Index.empty
          ~file_list:[ "a/main.tf"; "b/main.tf"; "c/main.tf" ]
          (R.of_view
             (R.View.make
                ~dirs:
                  (Sln_map.String.of_list
                     [
                       ("a", R.Dirs.Dir.make ());
                       ("b", R.Dirs.Dir.make ());
                       ("c", R.Dirs.Dir.make ());
                     ])
                ~stacks:
                  (R.Stacks.make
                     ~names:
                       (Sln_map.String.of_list
                          [
                            ("sa", stack "a");
                            ("sb", stack ~rules:(R.Stacks.Rules.make ~plan_after:[ "sa" ] ()) "b");
                            ("sc", stack ~rules:(R.Stacks.Rules.make ~plan_after:[ "sb" ] ()) "c");
                          ])
                     ())
                ()))
      in
      let config =
        CCResult.get_exn (Terrat_change_match3.synthesize_config ~index:R.Index.empty repo_config)
      in
      (* Only [a] and [c] change, so the stack [sb] has nothing in the run. *)
      let diff =
        Terrat_change.Diff.[ Change { filename = "a/main.tf" }; Change { filename = "c/main.tf" } ]
      in
      let matched = Terrat_change_match3.match_diff_list config diff in
      Oth.Assert.true_
        ~fail_msg:"the run is [a] and [c] only"
        (CCList.equal (CCList.equal CCString.equal) (dirs_of_layers matched) [ [ "a" ]; [ "c" ] ]);
      Oth.Assert.true_
        ~fail_msg:"re-layering the same dirspaces gives the same layers"
        (CCList.equal
           (CCList.equal CCString.equal)
           (dirs_of_layers (Terrat_change_match3.layers_of config (CCList.flatten matched)))
           (dirs_of_layers matched));
      ())

(* Contraction walks the configuration graph, not the run, so a long chain of
   dirspaces that have left the run must not cost more than the chain is long.
   The memo is what makes it one visit per dirspace rather than one per path.

   Measured: the layering alone takes 3ms at 1000 dirspaces, 8ms at 2000 and
   25ms at 4000, so it is linear in practice.  Without the memo it is the number
   of paths, which doubles with each level.  The bound below is loose enough for
   a loaded machine and still two orders of magnitude under a walk that lost the
   memo.  Most of this test's wall time is [synthesize_config], which compares
   every pair of dirspaces and is not what is being measured here. *)
let test_layers_of_contraction_is_not_quadratic =
  Oth.test ~name:"layers_of: contraction through a long chain stays cheap" (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let levels = 2000 in
      let name i = Printf.sprintf "d%04d" i in
      let dirs =
        CCList.map
          (fun i ->
            ( name i,
              if i = 0 then R.Dirs.Dir.make ()
              else
                R.Dirs.Dir.make
                  ~workspaces:
                    (Sln_map.String.of_list
                       [
                         ( "default",
                           R.Dirs.Workspace.make
                             ~when_modified:
                               (R.When_modified.make
                                  ~depends_on:(depends_on_q ("dir:" ^ name (i - 1)))
                                  ())
                             () );
                       ])
                  () ))
          (CCList.range' 0 levels)
      in
      let repo_config =
        derive
          ~ctx
          ~index:R.Index.empty
          ~file_list:(CCList.map (fun (d, _) -> d ^ "/main.tf") dirs)
          (R.of_view (R.View.make ~dirs:(Sln_map.String.of_list dirs) ()))
      in
      let config =
        CCResult.get_exn (Terrat_change_match3.synthesize_config ~index:R.Index.empty repo_config)
      in
      (* Every other dirspace has left the run, so every edge that is left has to
         be contracted through one that is gone. *)
      let subset =
        dirspace_configs_of_dirs
          config
          (CCList.map name (CCList.filter (fun i -> i mod 2 = 0) (CCList.range' 0 levels)))
      in
      let start = Unix.gettimeofday () in
      let layers = Terrat_change_match3.layers_of config subset in
      let elapsed = Unix.gettimeofday () -. start in
      Oth.Assert.true_
        ~fail_msg:(Printf.sprintf "layers = %d, expected %d" (CCList.length layers) (levels / 2))
        (CCList.length layers = levels / 2);
      Oth.Assert.true_
        ~fail_msg:(Printf.sprintf "contraction took %f seconds" elapsed)
        (elapsed < 1.0);
      ())

(* [synthesize_config] compares every pair of dirspaces to build the topology, so
   its cost grows with the square of the number of dirspaces.  What it does for
   each pair is what decides whether that is affordable, and the answer has to
   depend on how much the configuration actually declares.

   A dirspace that declares no [depends_on] and no stack rule cannot order
   anything, so its scan of every other dirspace is dead work and is skipped.
   That is the common shape: most directories declare nothing.

   Measured at 2000 dirspaces: the configuration where every directory declares a
   [depends_on] takes about 1 second, and the one that declares nothing takes
   about 0.005 seconds.  Before the skip the second was 0.05 seconds, ten times
   more.

   The assertion is the RATIO of the two, not a wall clock bound on either, so a
   machine that is uniformly slower moves both numbers together and the ratio
   stays where it is.

   A pause does not move them together.  A pause only ever ADDS time, and the two
   measurements are not the same size: the cheap one is about 0.005 seconds, so
   0.010 seconds of pause triples it, while the same 0.010 seconds disappears
   into a measurement of one second.  That is what failed this test on CI once,
   with the cheap shape at 0.018 seconds against an expensive shape of 0.736
   seconds -- a ratio of 40, which is below the 50 asserted here.

   The pause is a major collection, and its arrival is not chance.  The expensive
   shape runs first and leaves a large heap of garbage, so the collection of that
   garbage falls due during the cheap shape that follows it.  Measured with
   [Gc.quick_stat], a cheap sample that contains a major collection costs 0.0085
   to 0.0160 seconds and one that does not costs 0.0054 to 0.0080 seconds.

   Two things hold the measurement still.  [time_synthesize] collects the whole
   heap BEFORE it starts the clock, so a sample does not pay for the garbage of
   the sample before it; that alone took every one of 30 cheap samples to zero
   major collections.  Then the cheap shape is measured [samples] times and the
   FASTEST run is the one that counts, so an OS level pause, which no
   [Gc.full_major] can prevent, has to hit every sample to survive the minimum.

   The expensive shape needs no minimum.  A pause can only inflate it, and
   inflating it only raises the ratio, which is the safe direction. *)
let test_synthesize_config_skips_dirspaces_that_declare_nothing =
  Oth.test
    ~name:"synthesize_config skips the pair scan for a dirspace that declares nothing"
    (fun _ ->
      let module R = Terrat_base_repo_config_v1 in
      let dirspaces = 2000 in
      let samples = 5 in
      let name i = Printf.sprintf "d%04d" i in
      let depends_on_previous i =
        if i = 0 then R.Dirs.Dir.make ()
        else
          R.Dirs.Dir.make
            ~workspaces:
              (Sln_map.String.of_list
                 [
                   ( "default",
                     R.Dirs.Workspace.make
                       ~when_modified:
                         (R.When_modified.make
                            ~depends_on:(depends_on_q ("dir:" ^ name (i - 1)))
                            ())
                       () );
                 ])
            ()
      in
      let repo_config_of make_dir =
        let dirs = CCList.map (fun i -> (name i, make_dir i)) (CCList.range' 0 dirspaces) in
        derive
          ~ctx
          ~index:R.Index.empty
          ~file_list:(CCList.map (fun (d, _) -> d ^ "/main.tf") dirs)
          (R.of_view (R.View.make ~dirs:(Sln_map.String.of_list dirs) ()))
      in
      let time_synthesize repo_config =
        (* Before the clock, not during it: this pays off the garbage of whatever
           ran before, so the collection of it cannot land inside the window. *)
        Gc.full_major ();
        let start = Unix.gettimeofday () in
        let config =
          CCResult.get_exn (Terrat_change_match3.synthesize_config ~index:R.Index.empty repo_config)
        in
        let elapsed = Unix.gettimeofday () -. start in
        ignore config;
        elapsed
      in
      (* [synthesize_config] is a function of its arguments and holds no state
         between calls, so each sample repeats the same work on the same input and
         the samples differ only in what the machine did to them. *)
      let fastest_synthesize repo_config =
        CCList.fold_left
          (fun fastest _ -> CCFloat.min fastest (time_synthesize repo_config))
          infinity
          (CCList.range' 0 samples)
      in
      let every_dir_declares = time_synthesize (repo_config_of depends_on_previous) in
      let no_dir_declares = fastest_synthesize (repo_config_of (fun _ -> R.Dirs.Dir.make ())) in
      (* With the skip the ratio is about 250; without it, when both shapes walk
         every pair, it is about 20.  Fifty sits between the two with room on each
         side. *)
      Oth.Assert.true_
        ~fail_msg:
          (Printf.sprintf
             "declaring nothing (%f s, fastest of %d) must be far cheaper than declaring \
              everything (%f s)"
             no_dir_declares
             samples
             every_dir_declares)
        (no_dir_declares *. 50.0 < every_dir_declares);
      ())

let test =
  Oth.parallel
    [
      test_simple;
      test_workflow_idx;
      test_dir_match;
      test_dirspace_map;
      test_dir_file_pattern;
      test_workflow_idx_tag_in_dir;
      test_workflow_idx_multiple_dirs;
      test_workflow_override;
      test_dir_config_iam;
      test_dir_config_ebl;
      test_dir_config_ebl_modules;
      test_dir_config_ebl_and_modules;
      test_dir_config_s3;
      test_dir_config_lambda_json;
      test_dir_config_module;
      test_dir_config_null_file_patterns;
      test_recursive_dirs_template_dir;
      test_recursive_dirs_aws_prod;
      test_recursive_dirs_tags;
      test_recursive_dirs_without_tags;
      test_bad_dir_config_iam;
      test_bad_dir_config_ec2;
      test_bad_dir_config_ec2_root_dir_change;
      test_bad_dir_config_s3;
      test_module_dir_with_root_dir;
      test_large_directory_count_matching_files;
      test_large_directory_count_unmatching_files;
      (* FIX: This fails on ARM builds, for now just comment it out and fix later *)
      (* test_large_directory_count_matching_files; *)
      test_large_file_count_with_low_match_count;
      test_large_file_count_with_low_match_count_lesser_dir_depth;
      test_large_directory_count_non_default_when_modified;
      test_not_match;
      test_not_match_multiple;
      test_relative_path_file_pattern;
      test_relative_path_file_pattern_multiple_dots;
      test_index_basic;
      test_index_with_dirs_section;
      test_index_module_in_same_dir;
      test_index_symlinks;
      test_index_symlinks_dir_config;
      test_depends_on;
      test_depends_on_multiple_depends;
      test_depends_on_multiple_depends_2;
      test_depends_on_multiple_depends_disjoint;
      test_depends_on_cycle;
      test_depends_on_relative_dir;
      test_depends_on_prune_on_no_change_chain;
      test_depends_on_prune_on_no_change_all_pruned;
      test_force_matches_not_pruned;
      test_layer_is_earliest_possible;
      test_layer_is_earliest_possible_shared_dependent;
      test_collect_dependents_visits_each_dirspace_once;
      test_modified_by_pull_collects_depends_on;
      test_modified_by_cycle_terminates;
      test_files_in_same_dir_match_multiple_dirs;
      test_layers_of_dependency_outside_subset;
      test_layers_of_dependency_inside_subset;
      test_layers_of_contracts_through_a_missing_dirspace;
      test_apply_layers_of_counts_apply_after;
      test_layers_of_frees_a_branch_after_an_apply;
      test_depends_on_crossing_a_stack_boundary;
      test_depends_on_inside_a_nested_stack;
      test_depends_on_crossing_a_boundary_a_stack_rule_also_orders;
      test_depends_on_cycle_names_the_rule;
      test_layers_of_agrees_with_match_diff_list_through_an_empty_stack;
      test_layers_of_contraction_is_not_quadratic;
      test_synthesize_config_skips_dirspaces_that_declare_nothing;
      test_large_directory_timing;
    ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
