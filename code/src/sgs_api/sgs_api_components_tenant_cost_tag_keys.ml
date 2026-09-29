module Tag_keys = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { tag_keys : Tag_keys.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
