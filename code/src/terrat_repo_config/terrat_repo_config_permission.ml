module Items = struct
  type t = {
    id : string;
    permissions : string;
  }
  [@@deriving yojson { strict = true; meta = true }, make, show, eq]
end

type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
