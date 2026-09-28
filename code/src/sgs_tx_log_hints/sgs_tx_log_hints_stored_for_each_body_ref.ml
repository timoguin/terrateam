module Path = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  fq_address : string;
  path : Path.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
