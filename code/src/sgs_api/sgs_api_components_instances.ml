module Results = struct
  type t = Sgs_api_components_instance.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { results : Results.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
