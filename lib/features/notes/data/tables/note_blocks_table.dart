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
}
