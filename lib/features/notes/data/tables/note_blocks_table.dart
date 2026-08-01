import 'package:drift/drift.dart';

import 'notes_table.dart';

/// One block of a note, in [orderIndex] order.
///
/// [type] is 'text' | 'checkbox' | 'photo' (see NoteBlockType). [content] holds
/// the text (for text/checkbox) OR the image filename (for photo — the file
/// itself lives in <appDocs>/note_images/). [checked] is meaningful only for
/// checkbox blocks. Blocks CASCADE-delete with their note.
class NoteBlocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteId =>
      integer().references(Notes, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text().withLength(min: 1, max: 16)();
  TextColumn get content => text().nullable()();
  BoolColumn get checked => boolean().withDefault(const Constant(false))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  /// Whole-block formatting (Phase-1 rich text). Defaults = unformatted body.
  /// [headingLevel] 0 = body, 1/2/3 = H1/H2/H3 (text blocks only). The three
  /// flags apply to the whole line. `content` is never changed by formatting.
  IntColumn get headingLevel => integer().withDefault(const Constant(0))();
  BoolColumn get highlighted => boolean().withDefault(const Constant(false))();
  BoolColumn get bold => boolean().withDefault(const Constant(false))();
  BoolColumn get italic => boolean().withDefault(const Constant(false))();

  /// A7 (collapse under headings): true = this HEADING block's section is
  /// folded in the editor. Meaningful only on heading text blocks
  /// (headingLevel != 0); other block types ignore it. Default false → existing
  /// notes open fully expanded (no backfill).
  BoolColumn get collapsed => boolean().withDefault(const Constant(false))();
}
