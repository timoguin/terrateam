module Resources = struct
  type t = Sgs_api_components_unmanaged_resource.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  provider : string; [@default "aws"]
  resources : Resources.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
