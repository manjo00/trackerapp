import '../../../core/database/app_database.dart';
import '../data/models/note_block_type.dart';

/// A short one-line label for a block, used in the editor's "Reorder lines"
/// mode where blocks are shown as compact non-editable rows. Pure — no I/O.
///
/// - text/checkbox → the trimmed content, or a muted placeholder when empty.
/// - photo → the word "Photo" (the thumbnail carries the visual).
String blockLabel(NoteBlock block) {
  switch (NoteBlockType.parse(block.type)) {
    case NoteBlockType.photo:
      return 'Photo';
    case NoteBlockType.checkbox:
      final String text = (block.content ?? '').trim();
      return text.isEmpty ? 'Checklist item' : text;
    case NoteBlockType.text:
      final String text = (block.content ?? '').trim();
      return text.isEmpty ? 'Empty line' : text;
  }
}
