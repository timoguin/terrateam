type t = {
  skip_data_source_refresh : bool option; [@default None]
  skip_refresh : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
