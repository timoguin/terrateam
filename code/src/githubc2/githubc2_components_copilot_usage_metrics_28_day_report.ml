module Primary = struct
  module Download_links = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    download_links : Download_links.t;
    report_end_day : string;
    report_start_day : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
