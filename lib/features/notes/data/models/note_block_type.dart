/// The kinds of block a note can contain (Phase 1).
///
/// Persisted as [storageKey] in `note_blocks.type`. Phase 2 will add a
/// `heading` value; [parse] falls back to [text] for null/unknown so an older
/// value never crashes a newer build (and vice-versa).
enum NoteBlockType {
  text,
  checkbox,
  photo;

  /// Value stored in `note_blocks.type`.
  String get storageKey => name;

  /// Parses a stored value; null/unknown → [text] (safe default).
  static NoteBlockType parse(String? raw) => switch (raw) {
        'checkbox' => NoteBlockType.checkbox,
        'photo' => NoteBlockType.photo,
        _ => NoteBlockType.text,
      };
}
