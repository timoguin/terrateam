type t = {
  edges : int;
  instances : int;
  modules : int;
  providers : int;
  resources : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
