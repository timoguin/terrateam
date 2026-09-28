module Pages = struct
  type t = Sgs_api_components_actuator_bundle_cursors_page.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { pages : Pages.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
