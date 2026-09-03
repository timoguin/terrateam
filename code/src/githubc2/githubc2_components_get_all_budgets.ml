module Primary = struct
  module Budgets = struct
    type t = Githubc2_components_budget.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Effective_budget = struct
    module Primary = struct
      type t = {
        budget_amount : int;
        consumed_amount : float;
        id : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    budgets : Budgets.t;
    effective_budget : Effective_budget.t option; [@default None]
    has_next_page : bool option; [@default None]
    total_count : int option; [@default None]
    user : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
