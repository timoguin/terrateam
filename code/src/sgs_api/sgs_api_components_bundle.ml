module Capture_files = struct
  type t = Sgs_api_components_bundle_capture_file.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Files = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Hcl = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module State_ = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  capture_files : Capture_files.t option; [@default None]
  cursor : string option; [@default None]
  files : Files.t option; [@default None]
  hcl : Hcl.t;
  state : State_.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
