type t = {
  address : string;
  billed_cost : string;
  currency : string option; [@default None]
  line_count : int;
  window_end : string option; [@default None]
  window_start : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
