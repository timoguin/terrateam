module Attributes = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Dependencies = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Sensitive_attributes = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  address : string;
  attributes : Attributes.t option; [@default None]
  dependencies : Dependencies.t option; [@default None]
  module_ : string option; [@default None] [@key "module"]
  provider : string;
  sensitive_attributes : Sensitive_attributes.t option; [@default None]
  type_ : string; [@key "type"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
