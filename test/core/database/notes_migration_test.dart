import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';

void main() {
  test('v14 tables exist and accept inserts', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime(2026, 7, 10, 9);

    final nb = await db.into(db.notebooks).insert(
        NotebooksCompanion.insert(name: 'Rounds', createdAt: now));
    final note = await db.into(db.notes).insert(NotesCompanion.insert(
        notebookId: Value(nb), createdAt: now, updatedAt: now));
    await db.into(db.noteBlocks).insert(NoteBlocksCompanion.insert(
        noteId: note, type: 'text', content: const Value('hello')));

    expect((await db.select(db.notebooks).get()).single.name, 'Rounds');
    expect((await db.select(db.notes).get()).single.notebookId, nb);
    expect((await db.select(db.noteBlocks).get()).single.content, 'hello');
    await db.close();
  });
}
