(** Setup Admin Create Endpoint

    Creates the first admin user during initial setup. Only available when no users exist and OAuth
    is not configured. *)

(** POST /api/v1/setup/admin - Create initial admin user. [requirement] is what the edition requires
    before setup may proceed. *)
val run :
  requirement:Sgs_service_license.requirement ->
  Sgs_config.t ->
  Sgs_storage.t ->
  Brtl_rtng.Handler.t
