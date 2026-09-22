module Primary = struct
  type t = { pricehash : string option [@default None] [@key "priceHash"] }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Additional = struct
  type t = string option [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Additional)
