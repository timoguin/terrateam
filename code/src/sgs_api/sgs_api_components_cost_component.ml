type t = {
  hourly_cost : string option; [@default None]
  hourly_quantity : string option; [@default None]
  monthly_cost : string option; [@default None]
  monthly_quantity : string option; [@default None]
  name : string;
  price : string;
  unit : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
