module Users = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { users : Users.t } [@@deriving yojson { strict = false; meta = true }, make, show, eq]
