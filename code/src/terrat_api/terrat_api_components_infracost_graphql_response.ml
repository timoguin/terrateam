module Errors = struct
  type t = Terrat_api_components_infracost_graphql_error.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  data : Terrat_api_components_infracost_graphql_data.t option; [@default None]
  errors : Errors.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
