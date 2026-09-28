(** Password hashing and verification using PBKDF2-SHA256 *)

(* OWASP 2023 recommendation: PBKDF2-SHA256, 310k iterations *)
let iterations = 310_000

let hash password =
  (* Generate 32-byte random salt *)
  let salt = Mirage_crypto_rng.generate 32 in
  (* Hash password with PBKDF2-SHA256 *)
  let hash = Pbkdf.pbkdf2 ~prf:`SHA256 ~count:iterations ~dk_len:32l ~password ~salt in
  (* Format: $pbkdf2-sha256$iterations$salt_b64$hash_b64 *)
  Printf.sprintf
    "$pbkdf2-sha256$%d$%s$%s"
    iterations
    (Base64.encode_exn salt)
    (Base64.encode_exn hash)

let verify password hash_str =
  (* Parse hash string: $pbkdf2-sha256$iterations$salt_b64$hash_b64 *)
  match CCString.split_on_char '$' hash_str with
  | [ ""; "pbkdf2-sha256"; iter_str; salt_b64; hash_b64 ] -> (
      match (int_of_string_opt iter_str, Base64.decode salt_b64, Base64.decode hash_b64) with
      | Some iter_count, Ok salt, Ok expected_hash ->
          (* Re-hash the password with the same salt and iterations *)
          let computed_hash =
            Pbkdf.pbkdf2
              ~prf:`SHA256
              ~count:iter_count
              ~dk_len:(Int32.of_int (CCString.length expected_hash))
              ~password
              ~salt
          in
          (* Constant-time comparison to prevent timing attacks *)
          Eqaf.equal expected_hash computed_hash
      | _ -> false)
  | _ -> false

let validate_strength password =
  let len = CCString.length password in
  if len < 8 then Error "Password must be at least 8 characters"
  else if len > 128 then Error "Password must be at most 128 characters"
  else Ok ()
