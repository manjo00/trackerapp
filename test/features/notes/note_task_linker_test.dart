import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/data/dao/notes_dao.dart';
import 'package:life_tracker/features/notes/data/models/note_block_type.dart';
import 'package:life_tracker/features/notes/domain/note_task_linker.dart';
import 'package:life_tracker/features/tasks/data/dao/lists_dao.dart';
import 'package:life_tracker/features/tasks/data/dao/tasks_dao.dart';

void main() {
  late AppDatabase db;
  late NotesDao notesDao;
  late TasksDao tasksDao;
  late ListsDao listsDao;
  late NoteTaskLinker linker;
  final now = DateTime(2026, 7, 11, 8);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    notesDao = NotesDao(db);
    tasksDao = TasksDao(db);
    listsDao = ListsDao(db);
    linker = NoteTaskLinker(notesDao, tasksDao, listsDao);
  });
  tearDown(() async => db.close());

  /// Creates a note titled [title] with one empty [type] block; returns both.
  Future<(int, NoteBlock)> makeNoteWithBlock(
      {String title = '', NoteBlockType type = NoteBlockType.checkbox}) async {
    final noteId = await notesDao.createNote(now: now);
    if (title.isNotEmpty) await notesDao.updateNoteTitle(noteId, title, now);
    final blockId = await notesDao.addBlock(
        noteId: noteId, type: type, content: '', orderIndex: 0);
    return (noteId, (await notesDao.getBlock(blockId))!);
  }

  test('a token line spawns a task in a list named after the note', () async {
    final (noteId, block) = await makeNoteWithBlock(title: 'Bed 7 rounds');
    await linker.reconcileBlock(
        block: block, content: '@1450pm take sample from bed 7', now: now);

    final tasks = await tasksDao.getAllTasks();
    expect(tasks, hasLength(1));
    expect(tasks.single.title, 'take sample from bed 7');
    expect(tasks.single.dueTime, '14:50');
    expect(tasks.single.dueDate, '2026-07-11');
    expect(tasks.single.sourceNoteBlockId, block.id);

    final list = await listsDao.getListForNote(noteId);
    expect(list, isNotNull);
    expect(list!.name, 'Bed 7 rounds');
    expect(tasks.single.listId, list.id);
  });

  test('a title-less token borrows the note title', () async {
    final (_, block) = await makeNoteWithBlock(title: 'Morning obs');
    await linker.reconcileBlock(block: block, content: '@0900', now: now);
    expect((await tasksDao.getAllTasks()).single.title, 'Morning obs');
  });

  test('editing the line updates the same task (no duplicate)', () async {
    final (_, block) = await makeNoteWithBlock(title: 'N');
    await linker.reconcileBlock(block: block, content: '@0900 first', now: now);
    await linker.reconcileBlock(block: block, content: '@1030 second', now: now);

    final tasks = await tasksDao.getAllTasks();
    expect(tasks, hasLength(1));
    expect(tasks.single.title, 'second');
    expect(tasks.single.dueTime, '10:30');
  });

  test('removing the token deletes the task', () async {
    final (_, block) = await makeNoteWithBlock(title: 'N');
    await linker.reconcileBlock(block: block, content: '@0900 obs', now: now);
    expect(await tasksDao.getAllTasks(), hasLength(1));

    await linker.reconcileBlock(
        block: block, content: 'just a plain note now', now: now);
    expect(await tasksDao.getAllTasks(), isEmpty);
  });

  test('ticking the note checkbox completes the task, and vice-versa',
      () async {
    final (_, block) = await makeNoteWithBlock(title: 'N');
    await linker.reconcileBlock(block: block, content: '@0900 standup', now: now);
    final taskId = (await tasksDao.getAllTasks()).single.id;

    // Note → task.
    await notesDao.setBlockChecked(block.id, true);
    await linker.onBlockCheckedChanged(block, true);
    expect((await tasksDao.getTask(taskId))!.isCompleted, true);

    // Task → note.
    await linker.mirrorTaskCompletionToBlock(taskId, false);
    expect((await notesDao.getBlock(block.id))!.checked, false);
  });

  test('deleting the block cascades its task away', () async {
    final (_, block) = await makeNoteWithBlock(title: 'N');
    await linker.reconcileBlock(block: block, content: '@0900 obs', now: now);
    await notesDao.deleteBlock(block.id);
    expect(await tasksDao.getAllTasks(), isEmpty);
  });

  test('deleting the note cascades its task and its auto-list away', () async {
    final (noteId, block) = await makeNoteWithBlock(title: 'N');
    await linker.reconcileBlock(block: block, content: '@0900 obs', now: now);
    expect(await listsDao.getListForNote(noteId), isNotNull);

    await notesDao.deleteNote(noteId);
    expect(await tasksDao.getAllTasks(), isEmpty);
    expect(await listsDao.getListForNote(noteId), isNull);
  });
}
