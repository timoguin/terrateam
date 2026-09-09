(* Floor on [max_bytes]: a [\uXXXX] escape is six bytes and a codepoint four, so at any offset a
   safe cut lies within the previous nine bytes; sixteen keeps every fragment able to hold one. *)
let min_max_bytes = 16

(* Byte length of the escape sequence whose backslash is at [pos]. *)
let escape_len s pos =
  if pos + 1 < CCString.length s && CCChar.equal (CCString.get s (pos + 1)) 'u' then 6 else 2

(* Same shape as [Sln_utf8.split]: fold the codepoints, collect cut offsets, then [sub] the
   fragments out of the original. The fold additionally tracks the escape sequence it is inside
   ([escape_end], exclusive), because a backslash in a JSON text only ever opens an escape, and the
   last offset it could have cut at ([last_safe]) so that an overrun inside an escape retreats to it
   rather than cutting through. A fragment never starts inside an escape (cuts are safe by
   construction), so [last_safe] is always past [start] by the time an overrun can happen.

   The fold cannot stop early, so a malformed sequence is recorded ([malformed], the first offset)
   and the rest of the text is walked without effect; the result is decided once the fold is done. *)
let split ~max_bytes s =
  let max_bytes = max min_max_bytes max_bytes in
  let len = CCString.length s in
  let module St = struct
    type t = {
      cuts : int list;
      start : int;
      last_safe : int;
      escape_end : int;
      malformed : int option;
    }
  end in
  let st =
    Uutf.String.fold_utf_8
      (fun st pos -> function
        | `Malformed _ -> { st with St.malformed = CCOption.or_ ~else_:(Some pos) st.St.malformed }
        | `Uchar _ when CCOption.is_some st.St.malformed -> st
        | `Uchar c ->
            let next = pos + Uchar.utf_8_byte_length c in
            let safe = pos >= st.St.escape_end in
            let escape_end =
              if safe && Uchar.equal c (Uchar.of_char '\\') then pos + escape_len s pos
              else st.St.escape_end
            in
            let last_safe = if safe && pos > st.St.start then pos else st.St.last_safe in
            if next - st.St.start > max_bytes then
              (* Cut before the codepoint that would overrun the bound -- or, when that offset is
                 inside an escape, at the last offset that was not. *)
              let cut = if safe then pos else last_safe in
              { st with St.cuts = cut :: st.St.cuts; start = cut; last_safe = cut; escape_end }
            else { st with St.last_safe; escape_end })
      { St.cuts = []; start = 0; last_safe = 0; escape_end = 0; malformed = None }
      s
  in
  let rec fragments acc = function
    | a :: (b :: _ as rest) -> fragments (CCString.sub s a (b - a) :: acc) rest
    | _ -> CCList.rev acc
  in
  match st.St.malformed with
  | Some pos -> Error (`Malformed_utf8 pos)
  | None -> Ok (fragments [] (0 :: CCList.rev (len :: st.St.cuts)))
