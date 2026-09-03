module Primary = struct
  module Must_match = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Must_not_match = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    end_delimiter : string; [@default "\\z|[^0-9A-Za-z]"]
    must_match : Must_match.t option; [@default None]
    must_not_match : Must_not_match.t option; [@default None]
    name : string;
    pattern : string;
    start_delimiter : string; [@default "\\A|[^0-9A-Za-z]"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
