module Type = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Value = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  address : string;
  name : string;
  sensitive : bool option; [@default None]
  type_ : Type.t; [@key "type"]
  value : Value.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
