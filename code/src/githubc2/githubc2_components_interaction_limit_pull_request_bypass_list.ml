module Primary = struct
  module Users = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = { users : Users.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
