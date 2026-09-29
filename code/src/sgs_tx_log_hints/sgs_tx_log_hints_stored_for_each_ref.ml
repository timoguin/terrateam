module Keys = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  fq_address : string;
  keys : Keys.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
