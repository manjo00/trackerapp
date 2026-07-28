import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/archive/presentation/archive_providers.dart';
import 'package:life_tracker/features/notes/data/dao/notes_dao.dart';
import 'package:life_tracker/features/notes/data/models/note_block_type.dart';
import 'package:life_tracker/features/tasks/data/dao/tasks_dao.dart';

void main() {
  late AppDatabase db;
  late ArchiveService archive;
  late NotesDao notes;
  late TasksDao tasks;
  final now = DateTime(2026, 7, 22, 9);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    archive = ArchiveService(db);
    notes = NotesDao(db);
    tasks = TasksDao(db);
  });
  tearDown(() async => db.close());

  Future<(int blockId, int taskId)> seed(String content) async {
    final int noteId = await notes.createNote(now: now);
    final int blockId = await notes.addBlock(
        noteId: noteId,
        type: NoteBlockType.checkbox,
        content: content,
        orderIndex: 0);
    final int taskId = await db.into(db.tasks).insert(TasksCompanion.insert(
        title: 'draw', createdAt: now, sourceNoteBlockId: Value(blockId)));
    return (blockId, taskId);
  }

  test('archiving a note-linked task strips the token but keeps the line',
      () async {
    final (blockId, taskId) = await seed('@0900 draw');
    await archive.archiveTask(taskId, now);

    expect((await tasks.getTask(taskId))!.archivedAt, isNotNull);
    expect((await notes.getBlock(blockId))!.content, 'draw');
  });

  test('deleting a note-linked task deletes the note line and the task',
      () async {
    final (blockId, taskId) = await seed('@0900 draw');
    await archive.deleteTask(taskId);

    expect(await tasks.getTask(taskId), isNull);
    expect(await notes.getBlock(blockId), isNull);
  });

  test('deleting an ordinary task leaves notes untouched', () async {
    final int taskId = await db.into(db.tasks).insert(
        TasksCompanion.insert(title: 'plain', createdAt: now));
    await archive.deleteTask(taskId);
    expect(await tasks.getTask(taskId), isNull);
  });
}
