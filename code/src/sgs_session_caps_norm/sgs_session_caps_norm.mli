(** Normalize a capabilities object so every allow-list is in its canonical, evaluation-faithful
    form (see {!Sg_caps_match.canonicalize_list}): e.g. [[]] becomes [["!*"]] and [["a"; "*"]]
    becomes [["*"]]. A [null] state value ("all resources") is left unchanged.

    Capabilities are normalized liberally on read — before being returned from a session or a user —
    so that the stored representation need not be normalized and every downstream consumer (display,
    masking, session/transaction enforcement) sees the same canonical shape. *)
val normalize : Sgs_session_caps_capabilities.t -> Sgs_session_caps_capabilities.t
