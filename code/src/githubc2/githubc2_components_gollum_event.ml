module Primary = struct
  module Pages = struct
    module Items = struct
      module Primary = struct
        type t = {
          action : string option; [@default None]
          html_url : string option; [@default None]
          page_name : string option; [@default None]
          sha : string option; [@default None]
          summary : string option; [@default None]
          title : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = { pages : Pages.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
