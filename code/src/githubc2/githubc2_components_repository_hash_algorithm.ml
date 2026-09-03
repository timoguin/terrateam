module Primary = struct
  module Hash_algorithm = struct
    let t_of_yojson = function
      | `String "sha1" -> Ok `Sha1
      | `String "sha256" -> Ok `Sha256
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Sha1 -> `String "sha1"
      | `Sha256 -> `String "sha256"

    type t =
      ([ `Sha1
       | `Sha256
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = { hash_algorithm : Hash_algorithm.t }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
