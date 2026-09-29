module Complete = struct
  module Parameters = struct
    type t = {
      provider : string;
      rd : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Found = struct end
    module Unauthorized = struct end
    module Internal_server_error = struct end

    type t =
      [ `Found
      | `Unauthorized
      | `Internal_server_error
      ]
    [@@deriving show, eq]

    let t =
      [
        ("302", fun _ -> Ok `Found);
        ("401", fun _ -> Ok `Unauthorized);
        ("500", fun _ -> Ok `Internal_server_error);
      ]
  end

  let url = "/api/v1/oauth2/{provider}/complete"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("provider", Var (params.provider, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("rd", Var (params.rd, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end
