module Api = Terrat_vcs_api_github
module Repo_config = Terrat_vcs_service_github_repo_config

let entry ?(kind = `File) name size = Api.Directory_entry.make ~kind ~name ~size ()
let candidate path size = Some { Repo_config.Candidate.path; size }

let check ~name ?(directory = ".stategraph") ?(basename = "config") ~entries ~expected () =
  Oth.test ~name ~tags:[ "repo_config_listing" ] (fun _ ->
      Oth.Assert.Eq.option
        ~eq:Repo_config.Candidate.equal
        ~pp:Repo_config.Candidate.pp
        ~expected
        ~actual:(Repo_config.Tests.find_candidate entries ~directory ~basename);
      ())

let tests =
  Oth.parallel
    [
      check
        ~name:"yml"
        ~entries:[ entry "config.yml" 10 ]
        ~expected:(candidate ".stategraph/config.yml" 10)
        ();
      check
        ~name:"yaml"
        ~entries:[ entry "config.yaml" 11 ]
        ~expected:(candidate ".stategraph/config.yaml" 11)
        ();
      check
        ~name:"yml wins over yaml"
        ~entries:[ entry "config.yaml" 15; entry "config.yml" 16 ]
        ~expected:(candidate ".stategraph/config.yml" 16)
        ();
      check
        ~name:"zero byte file stays selected"
        ~entries:[ entry "config.yml" 0; entry "config.yaml" 18 ]
        ~expected:(candidate ".stategraph/config.yml" 0)
        ();
      check
        ~name:"directory named config yml is ignored"
        ~entries:[ entry ~kind:`Dir "config.yml" 0; entry "config.yaml" 17 ]
        ~expected:(candidate ".stategraph/config.yaml" 17)
        ();
      check
        ~name:"symlink named config yml is ignored"
        ~entries:[ entry ~kind:`Symlink "config.yml" 21 ]
        ~expected:None
        ();
      check ~name:"empty directory" ~entries:[] ~expected:None ();
      check ~name:"unrelated file" ~entries:[ entry "other.yml" 20 ] ~expected:None ();
      check
        ~name:"another directory"
        ~directory:".terrateam"
        ~entries:[ entry "config.yml" 12 ]
        ~expected:(candidate ".terrateam/config.yml" 12)
        ();
      (* The centralized repository reads several basenames out of one
         directory. *)
      check
        ~name:"another basename"
        ~directory:"config"
        ~basename:"defaults"
        ~entries:[ entry "config.yml" 30; entry "defaults.yaml" 31 ]
        ~expected:(candidate "config/defaults.yaml" 31)
        ();
    ]

let () = Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun () -> ()) (fun _ -> tests)
