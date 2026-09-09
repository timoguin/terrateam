(** Splitting the text of a JSON value into fragments that each decode on their own.

    [split ~max_bytes s] cuts [s], the UTF-8 text of a JSON value, into fragments of at most
    [max_bytes] bytes whose concatenation is [s]. Every cut lands between two codepoints
    ({!Sln_utf8.split}'s guarantee) and outside any escape sequence (the two-byte ones such as a
    backslash followed by [n], and the six-byte [backslash-u] ones), so a fragment on its own is
    valid UTF-8 and, for a fragment of a JSON string literal, valid escaped text: wrapped in quotes
    it parses as a JSON string. The first and last fragments carry the literal's own quotes.

    That is what lets a reader show a large stored value one fragment at a time -- the point of
    storing it in fragments -- instead of having to fetch every fragment before it can decode any.

    For example, at the [16]-byte floor the cut that would fall between the [backslash] and the [n]
    of the ["\\n"] escape is moved back to the last boundary before it (the same happens for a cut
    that would land inside the two-byte ["é"]):
    {[
    split ~max_bytes:16 {|"abcdefghijklmn\né"|} = Ok [ {|"abcdefghijklmn|}; {|\né"|} ]
    ]}

    [max_bytes] is floored at {!min_max_bytes}. Invalid UTF-8 is [`Malformed_utf8], carrying the
    byte offset of the first offending sequence: there is no codepoint boundary to cut such a text
    on, so the caller decides what a text it cannot fragment safely becomes. *)
val split : max_bytes:int -> string -> (string list, [> `Malformed_utf8 of int ]) result

(** The floor {!split} applies to [max_bytes]: 16. An escape is at most 6 bytes and a codepoint at
    most 4, so within any 16 bytes there is always a safe cut. Necessarily larger than
    {!Sln_utf8.min_max_bytes}, which only has codepoints to fit: a fragment here must hold an escape
    and the codepoints around it. *)
val min_max_bytes : int
