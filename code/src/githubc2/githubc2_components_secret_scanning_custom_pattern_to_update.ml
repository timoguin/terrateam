module V0 = struct
  module Primary = struct
    module Must_match = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Must_not_match = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      custom_pattern_version : string option; [@default None]
      end_delimiter : string option; [@default None]
      must_match : Must_match.t option; [@default None]
      must_not_match : Must_not_match.t option; [@default None]
      pattern : string;
      start_delimiter : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module V1 = struct
  module Primary = struct
    module Must_match = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Must_not_match = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      custom_pattern_version : string option; [@default None]
      end_delimiter : string option; [@default None]
      must_match : Must_match.t option; [@default None]
      must_not_match : Must_not_match.t option; [@default None]
      pattern : string option; [@default None]
      start_delimiter : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module V2 = struct
  module Primary = struct
    module Must_match = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Must_not_match = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      custom_pattern_version : string option; [@default None]
      end_delimiter : string;
      must_match : Must_match.t option; [@default None]
      must_not_match : Must_not_match.t option; [@default None]
      pattern : string option; [@default None]
      start_delimiter : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module V3 = struct
  module Primary = struct
    module Must_match = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Must_not_match = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      custom_pattern_version : string option; [@default None]
      end_delimiter : string option; [@default None]
      must_match : Must_match.t;
      must_not_match : Must_not_match.t option; [@default None]
      pattern : string option; [@default None]
      start_delimiter : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module V4 = struct
  module Primary = struct
    module Must_match = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Must_not_match = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      custom_pattern_version : string option; [@default None]
      end_delimiter : string option; [@default None]
      must_match : Must_match.t option; [@default None]
      must_not_match : Must_not_match.t;
      pattern : string option; [@default None]
      start_delimiter : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t =
  | V0 of V0.t
  | V1 of V1.t
  | V2 of V2.t
  | V3 of V3.t
  | V4 of V4.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.any_of
    (let open CCResult in
     [
       (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
       (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
       (fun v -> map (fun v -> V2 v) (V2.of_yojson v));
       (fun v -> map (fun v -> V3 v) (V3.of_yojson v));
       (fun v -> map (fun v -> V4 v) (V4.of_yojson v));
     ])

let to_yojson = function
  | V0 v -> V0.to_yojson v
  | V1 v -> V1.to_yojson v
  | V2 v -> V2.to_yojson v
  | V3 v -> V3.to_yojson v
  | V4 v -> V4.to_yojson v
