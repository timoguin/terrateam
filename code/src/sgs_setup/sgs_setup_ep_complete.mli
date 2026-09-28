(** POST /api/v1/setup/complete — mark setup complete. [requirement] is what the edition requires
    before setup may complete (see {!Sgs_service_license.passes_license_gate}). *)
val run :
  requirement:Sgs_service_license.requirement ->
  Sgs_config.t ->
  Sgs_storage.t ->
  Brtl_rtng.Handler.t
