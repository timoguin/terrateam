module Results = struct
  type t = Sgs_api_components_github_unclaimed_installation.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  has_more : bool;
  limit : int;
  next_cursor : string option; [@default None]
  results : Results.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
