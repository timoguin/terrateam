(* RFD 2110, "Unit tests: output comparison".  Each case gives the baseline and
   the current outputs of a dirspace and a path into them, and says whether the
   value at that path changed.  A path of [None] is a bare [outputs:dir], which
   asks whether any output changed. *)

module Od = Terrat_output_diff

type case = {
  id : string;
  shape : Od.shape;
  baseline : string option;
  current : string option;
  path : string option;
  changed : bool;
}

let raw ?path ~baseline ~current id changed =
  { id; shape = Od.Raw; baseline; current; path; changed }

let tf ?path ~baseline ~current id changed =
  { id; shape = Od.Tf_wrapped; baseline; current; path; changed }

let db_type = {|["object", {"host": "string", "port": "number"}]|}

let tf_db ~host ~port =
  Printf.sprintf
    {|{"db": {"sensitive": false, "type": %s, "value": {"host": "%s", "port": %d}}}|}
    db_type
    host
    port

let cases =
  [
    raw
      "OC-1"
      ~path:"a.b"
      ~baseline:(Some {|{"a": {"b": 1}}|})
      ~current:(Some {|{"a": {"b": 1}}|})
      false;
    raw
      "OC-2"
      ~path:"a.b"
      ~baseline:(Some {|{"a": {"b": 1}}|})
      ~current:(Some {|{"a": {"b": 2}}|})
      true;
    raw
      "OC-3 key order"
      ~path:"a"
      ~baseline:(Some {|{"a": {"b": 1, "c": 2}}|})
      ~current:(Some {|{"a": {"c": 2, "b": 1}}|})
      false;
    raw
      "OC-4 list order"
      ~path:"a"
      ~baseline:(Some {|{"a": [1, 2]}|})
      ~current:(Some {|{"a": [2, 1]}|})
      true;
    raw
      "OC-5"
      ~path:"a.b"
      ~baseline:(Some {|{"a": {"b": 1}}|})
      ~current:(Some {|{"a": {"b": 1, "c": 3}}|})
      false;
    raw
      "OC-6"
      ~path:"a"
      ~baseline:(Some {|{"a": {"b": 1}}|})
      ~current:(Some {|{"a": {"b": 1, "c": 3}}|})
      true;
    raw "OC-7 absent is null" ~path:"a" ~baseline:(Some {|{}|}) ~current:(Some {|{"a": 1}|}) true;
    raw "OC-8" ~path:"a" ~baseline:(Some {|{"a": 1}|}) ~current:(Some {|{}|}) true;
    raw
      "OC-9 absent outputs equals null"
      ~path:"a"
      ~baseline:None
      ~current:(Some {|{"a": null}|})
      false;
    raw
      "OC-10 path absent in both"
      ~path:"x.y"
      ~baseline:(Some {|{"a": 1}|})
      ~current:(Some {|{"a": 1}|})
      false;
    raw
      "OC-11 type differs"
      ~path:"a"
      ~baseline:(Some {|{"a": "1"}|})
      ~current:(Some {|{"a": 1}|})
      true;
    tf
      "OC-12 sensitive value"
      ~path:"pw"
      ~baseline:(Some {|{"pw": {"sensitive": true, "type": "string", "value": "x"}}|})
      ~current:(Some {|{"pw": {"sensitive": true, "type": "string", "value": "y"}}|})
      true;
    tf
      "OC-13 compare value only"
      ~path:"pw"
      ~baseline:(Some {|{"pw": {"sensitive": false, "type": "string", "value": "x"}}|})
      ~current:(Some {|{"pw": {"sensitive": true, "type": "string", "value": "x"}}|})
      false;
    tf
      "OC-14"
      ~path:"ips"
      ~baseline:
        (Some {|{"ips": {"sensitive": false, "type": ["tuple", ["string"]], "value": ["a"]}}|})
      ~current:
        (Some
           {|{"ips": {"sensitive": false, "type": ["tuple", ["string", "string"]], "value": ["a", "b"]}}|})
      true;
    tf
      "OC-15 path selects inside value (A1)"
      ~path:"db.host"
      ~baseline:(Some (tf_db ~host:"h1" ~port:1))
      ~current:(Some (tf_db ~host:"h1" ~port:2))
      false;
    tf
      "OC-16 path selects inside value (A1)"
      ~path:"db.host"
      ~baseline:(Some (tf_db ~host:"h1" ~port:1))
      ~current:(Some (tf_db ~host:"h2" ~port:1))
      true;
    raw
      "OC-17 custom"
      ~path:"db.host"
      ~baseline:(Some {|{"db": {"host": "h1"}}|})
      ~current:(Some {|{"db": {"host": "h2"}}|})
      true;
    raw
      "OC-18 any output, none changed"
      ~baseline:(Some {|{"a": 1, "b": {"c": [1, 2]}}|})
      ~current:(Some {|{"b": {"c": [1, 2]}, "a": 1}|})
      false;
    raw
      "OC-19 any output, one changed"
      ~baseline:(Some {|{"a": 1, "b": 1}|})
      ~current:(Some {|{"a": 1, "b": 2}|})
      true;
    (* Cases the RFD table does not list, which close gaps a wrong implementation
       could pass through. *)
    tf
      "OC-20 any output, only sensitive and type changed"
      ~baseline:(Some {|{"pw": {"sensitive": false, "type": "string", "value": "x"}}|})
      ~current:(Some {|{"pw": {"sensitive": true, "type": ["list", "string"], "value": "x"}}|})
      false;
    raw "OC-21 no outputs on both sides" ~path:"a" ~baseline:None ~current:None false;
    raw "OC-22 outputs removed" ~path:"a" ~baseline:(Some {|{"a": 1}|}) ~current:None true;
    tf
      "OC-23 an output with no value key is compared as it is"
      ~path:"db.host"
      ~baseline:(Some {|{"db": {"host": "h1"}}|})
      ~current:(Some {|{"db": {"host": "h2"}}|})
      true;
    raw
      "OC-24 JSON that is not an object is no outputs"
      ~baseline:(Some {|[1]|})
      ~current:(Some {|[2]|})
      false;
  ]

let test_of_case { id; shape; baseline; current; path; changed } =
  Oth.test ~tags:[ "rfd_2110" ] ~name:id (fun _ ->
      let t =
        {
          Od.shape;
          baseline = CCOption.map Yojson.Safe.from_string baseline;
          current = CCOption.map Yojson.Safe.from_string current;
        }
      in
      let path = CCOption.map (CCString.split_on_char '.') path in
      Oth.Assert.Eq.bool ~expected:changed ~actual:(Od.changed t ~path);
      ())

let test = Oth.parallel (CCList.map test_of_case cases)

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
