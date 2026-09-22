module Extensions = struct
  type t = { code : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  extensions : Extensions.t;
  message : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
