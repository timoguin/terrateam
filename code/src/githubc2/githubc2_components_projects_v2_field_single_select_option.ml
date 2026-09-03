module Color = struct
  let t_of_yojson = function
    | `String "BLUE" -> Ok `BLUE
    | `String "GRAY" -> Ok `GRAY
    | `String "GREEN" -> Ok `GREEN
    | `String "ORANGE" -> Ok `ORANGE
    | `String "PINK" -> Ok `PINK
    | `String "PURPLE" -> Ok `PURPLE
    | `String "RED" -> Ok `RED
    | `String "YELLOW" -> Ok `YELLOW
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `BLUE -> `String "BLUE"
    | `GRAY -> `String "GRAY"
    | `GREEN -> `String "GREEN"
    | `ORANGE -> `String "ORANGE"
    | `PINK -> `String "PINK"
    | `PURPLE -> `String "PURPLE"
    | `RED -> `String "RED"
    | `YELLOW -> `String "YELLOW"

  type t =
    ([ `BLUE
     | `GRAY
     | `GREEN
     | `ORANGE
     | `PINK
     | `PURPLE
     | `RED
     | `YELLOW
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  color : Color.t option; [@default None]
  description : string option; [@default None]
  name : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
