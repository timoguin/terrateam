let test_of_string =
  Oth.test ~tags:[ "brand" ] ~name:"of_string accepts both brands" (fun _ ->
      (match Terrat_brand.of_string "stategraph" with
      | Some Terrat_brand.Stategraph -> ()
      | _ -> failwith "stategraph did not parse");
      (match Terrat_brand.of_string "terrateam" with
      | Some Terrat_brand.Terrateam -> ()
      | _ -> failwith "terrateam did not parse");
      match Terrat_brand.of_string "acme" with
      | None -> ()
      | Some _ -> failwith "an unknown brand parsed")

let test_to_terrateam =
  Oth.test ~tags:[ "brand" ] ~name:"to_terrateam rewrites every brand form" (fun _ ->
      CCList.iter
        (fun (before, after) ->
          let got = Terrat_brand.to_terrateam before in
          if not (CCString.equal got after) then
            failwith (Printf.sprintf "%S became %S, expected %S" before got after))
        [
          ("Stategraph", "Terrateam");
          ("Stategraph's Console", "Terrateam's Console");
          ("stategraph apply", "terrateam apply");
          ("`stategraph plan`", "`terrateam plan`");
          ("support@stategraph.com", "support@terrateam.io");
          ("support@@stategraph.com", "support@@terrateam.io");
          ("https://stategraph.com/slack", "https://terrateam.io/slack");
          ("https://stategraph.com/pricing", "https://terrateam.io/pricing");
          ("`.stategraph/config.yml`", "`.terrateam/config.yml`");
        ])

let test_terrateam_text_unchanged =
  Oth.test ~tags:[ "brand" ] ~name:"to_terrateam leaves Terrateam text alone" (fun _ ->
      CCList.iter
        (fun s ->
          if not (CCString.equal (Terrat_brand.to_terrateam s) s) then
            failwith (Printf.sprintf "%S was rewritten" s))
        [
          "terrateam apply";
          "Terrateam Console";
          "https://terrateam.io/docs/configuration";
          "https://docs.terrateam.io/getting-started";
          "support@terrateam.io";
        ])

let test_idempotent =
  Oth.test ~tags:[ "brand" ] ~name:"to_terrateam is idempotent" (fun _ ->
      let s = "Stategraph says `stategraph apply`, see https://stategraph.com/pricing" in
      let once = Terrat_brand.to_terrateam s in
      if not (CCString.equal (Terrat_brand.to_terrateam once) once) then
        failwith "a second rewrite changed the text")

let test =
  Oth.parallel [ test_of_string; test_to_terrateam; test_terrateam_text_unchanged; test_idempotent ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
