/// The kinds of block a note can contain.
///
/// Persisted as [storageKey] in `note_blocks.type`. [parse] falls back to
/// [text] for null/unknown so an older value never crashes a newer build (and
/// vice-versa). Headings are NOT a separate type — they are a `headingLevel`
/// flag on a text block (see NoteBlocks). [divider] is a contentless
/// horizontal separator.
enum NoteBlockType {
  text,
  checkbox,
  photo,
  divider;

  /// Value stored in `note_blocks.type`.
  String get storageKey => name;

  /// Parses a stored value; null/unknown → [text] (safe default).
  static NoteBlockType parse(String? raw) => switch (raw) {
        'checkbox' => NoteBlockType.checkbox,
        'photo' => NoteBlockType.photo,
        'divider' => NoteBlockType.divider,
        _ => NoteBlockType.text,
      };
}
