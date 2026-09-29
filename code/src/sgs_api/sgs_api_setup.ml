module Status = struct
  module Parameters = struct end

  module Responses = struct
    module OK = struct
      type t = Sgs_api_components.Setup_status_response.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Internal_server_error = struct end

    type t =
      [ `OK of OK.t
      | `Internal_server_error
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("500", fun _ -> Ok `Internal_server_error);
      ]
  end

  let url = "/api/v1/setup/status"

  let make () =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Magic_claim = struct
  module Parameters = struct end

  module Request_body = struct
    type t = Sgs_api_components.Setup_magic_claim_request.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module Created = struct
      type t = Sgs_api_components.Setup_admin_response.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Bad_request = struct end
    module Forbidden = struct end
    module Conflict = struct end
    module Service_unavailable = struct end

    type t =
      [ `Created of Created.t
      | `Bad_request
      | `Forbidden
      | `Conflict
      | `Service_unavailable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("409", fun _ -> Ok `Conflict);
        ("503", fun _ -> Ok `Service_unavailable);
      ]
  end

  let url = "/api/v1/setup/magic-claim"

  let make ~body =
   fun () ->
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Admin = struct
  module Parameters = struct end

  module Request_body = struct
    type t = Sgs_api_components.Setup_admin_request.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module Created = struct
      type t = Sgs_api_components.Setup_admin_response.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Bad_request = struct end
    module Forbidden = struct end
    module Conflict = struct end

    type t =
      [ `Created of Created.t
      | `Bad_request
      | `Forbidden
      | `Conflict
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("409", fun _ -> Ok `Conflict);
      ]
  end

  let url = "/api/v1/setup/admin"

  let make ~body =
   fun () ->
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end
