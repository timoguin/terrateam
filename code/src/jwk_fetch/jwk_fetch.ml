module Http = Cohttp_abb.Make(Abb)

type err = [ Cohttp_abb.request_err | `Bad_response ]

let tls_config =
  let cfg = Otls.Tls_config.create () in
  Otls.Tls_config.insecure_noverifycert cfg;
  cfg

let get_max_age cache_control =
  let vs = CCString.split_on_char ',' cache_control in
  let assoc =
    CCList.map
      (fun s ->
         let s = CCString.trim s in
         CCOpt.get_or
           ~default:(s, "")
           (CCString.Split.left ~by:"=" s))
      vs
  in
  match CCList.Assoc.get ~eq:CCString.equal "max-age" assoc with
    | Some max_age -> CCOpt.get_or ~default:0 (CCInt.of_string max_age)
    | None -> 0

let fetch uri =
  let open Abbs_future_combinators.Infix_result_monad in
  Http.Client.call ~tls_config `GET uri
  >>= function
  | (resp, body) when resp.Http.Response.status = `OK ->
    let headers = Http.Response.headers resp in
    let cache_control = CCOpt.get_or ~default:"" (Cohttp.Header.get headers "cache-control") in
    let max_age = get_max_age cache_control in
    begin match Jwk.of_string body with
      | Some jwk ->
        Abb.Future.return (Ok (jwk, max_age))
      | None ->
        Abb.Future.return (Error `Bad_response)
    end
  | _ ->
    Abb.Future.return (Error `Bad_response)