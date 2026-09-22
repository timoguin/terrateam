type t = {
  query : string;
  variables : Terrat_api_components_infracost_query_variables.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
