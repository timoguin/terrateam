(** GET /api/v1/license/status for the open-source edition *)

val run : Sgs_config.t -> Sgs_storage.t -> Brtl_rtng.Handler.t
