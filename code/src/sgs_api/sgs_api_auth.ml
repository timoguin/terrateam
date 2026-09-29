module Logout = struct
  module Parameters = struct
    type t = { rd : string option [@default None] } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Found = struct end

    type t = [ `Found ] [@@deriving show, eq]

    let t = [ ("302", fun _ -> Ok `Found) ]
  end

  let url = "/api/v1/logout"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("rd", Var (params.rd, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end
