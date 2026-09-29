(** Password hashing and verification using PBKDF2-SHA256 *)

(** [hash password] hashes a password using PBKDF2-SHA256 with 310,000 iterations (OWASP 2023
    recommendation). Returns a formatted hash string: "$pbkdf2-sha256$310000$salt_b64$hash_b64" *)
val hash : string -> string

(** [verify password hash_str] verifies that [password] matches the given [hash_str]. Uses
    constant-time comparison to prevent timing attacks. *)
val verify : string -> string -> bool

(** [validate_strength password] checks if password meets minimum requirements. Returns [Ok ()] if
    valid, [Error msg] otherwise. Requirements: 8-128 characters *)
val validate_strength : string -> (unit, string) result
