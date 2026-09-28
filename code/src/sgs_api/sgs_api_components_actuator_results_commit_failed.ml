module State_ = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Uploaded_files = struct
  type t = Sgs_api_components_uploaded_file.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  failure : Sgs_api_components_actuator_results_failure.t;
  state : State_.t;
  uploaded_files : Uploaded_files.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
