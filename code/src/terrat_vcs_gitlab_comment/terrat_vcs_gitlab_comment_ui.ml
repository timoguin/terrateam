module Ui = struct
  (* GitLab has no console run pages, so the brand selects nothing. *)
  let work_manifest_url ~brand:_ _config _account _pull_number _work_manifest = None
end
