import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';

void main() {
  test('v15 link columns exist and CASCADE from the note side', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime(2026, 7, 11, 9);

    // A note with one block, and a task/list wired to it via the v15 columns.
    final note = await db.into(db.notes).insert(
        NotesCompanion.insert(createdAt: now, updatedAt: now));
    final block = await db.into(db.noteBlocks).insert(
        NoteBlocksCompanion.insert(noteId: note, type: 'checkbox'));
    final list = await db.into(db.taskLists).insert(TaskListsCompanion.insert(
        name: 'N', createdAt: now, sourceNoteId: Value(note)));
    await db.into(db.tasks).insert(TasksCompanion(
          title: const Value('obs'),
          createdAt: Value(now),
          listId: Value(list),
          sourceNoteBlockId: Value(block),
        ));

    expect((await db.select(db.tasks).get()).single.sourceNoteBlockId, block);
    expect((await db.select(db.taskLists).get()).single.sourceNoteId, note);

    // Deleting the note removes its block → its task (CASCADE chain) and its
    // auto-created list (CASCADE on sourceNoteId).
    await (db.delete(db.notes)..where((n) => n.id.equals(note))).go();
    expect(await db.select(db.tasks).get(), isEmpty);
    expect(await db.select(db.taskLists).get(), isEmpty);

    await db.close();
  });
}
