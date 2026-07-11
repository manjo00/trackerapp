import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../tasks/data/dao/lists_dao.dart';
import '../../tasks/data/dao/tasks_dao.dart';
import '../data/dao/notes_dao.dart';
import 'task_token_parser.dart';

/// Keeps a note line and its auto-created task in sync.
///
/// A line that starts with an "@time" token (see [TaskTokenParser]) spawns a
/// task, filed under a list that is auto-created per note (`task_lists`
/// .sourceNoteId). The task links back to its block (`tasks.sourceNoteBlockId`).
///
/// This class owns the *cross-feature* coordination, so neither the notes nor
/// the tasks repository has to know about the other. It only reconciles/mirrors;
/// the structural delete rules (delete a block ⇒ delete its task; delete a note
/// ⇒ delete its list + tasks) are enforced by the database via ON DELETE
/// CASCADE, so they need no code here.
class NoteTaskLinker {
  NoteTaskLinker(this._notesDao, this._tasksDao, this._listsDao);

  final NotesDao _notesDao;
  final TasksDao _tasksDao;
  final ListsDao _listsDao;

  static final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

  /// Reconciles the task for [block] after its text changed to [content].
  ///
  /// - token present, no task yet  → create the note's list (if needed) + task
  /// - token present, task exists  → update its title / time / date / list
  /// - token gone                  → delete the task
  Future<void> reconcileBlock({
    required NoteBlock block,
    required String content,
    required DateTime now,
  }) async {
    final ParsedTaskToken? parsed = TaskTokenParser.parse(content, now: now);
    final Task? existing = await _tasksDao.getTaskForBlock(block.id);

    if (parsed == null) {
      // The line no longer describes a task — remove the one it used to.
      if (existing != null) await _tasksDao.deleteTask(existing.id);
      return;
    }

    final Note? note = await _notesDao.getNote(block.noteId);
    final String noteTitle = note?.title.trim() ?? '';
    // Decision (see CLAUDE.md "Note→task open questions"): a title-less token
    // borrows the note's title, falling back to "Reminder" for an untitled note.
    final String title = parsed.title.isNotEmpty
        ? parsed.title
        : (noteTitle.isNotEmpty ? noteTitle : 'Reminder');
    final String dueDate = parsed.date ?? _dateFmt.format(now);
    final int listId = await _ensureNoteList(block.noteId, noteTitle, now);

    if (existing == null) {
      await _tasksDao.insertTask(TasksCompanion(
        title: Value(title),
        dueDate: Value(dueDate),
        dueTime: Value(parsed.time),
        createdAt: Value(now),
        listId: Value(listId),
        sourceNoteBlockId: Value(block.id),
        // A checkbox line that's already ticked starts its task done.
        isCompleted: Value(block.checked),
      ));
    } else {
      await _tasksDao.updateTask(TasksCompanion(
        id: Value(existing.id),
        title: Value(title),
        dueDate: Value(dueDate),
        dueTime: Value(parsed.time),
        listId: Value(listId),
      ));
    }
  }

  /// Mirrors a checkbox tick in the note onto its task's completion.
  Future<void> onBlockCheckedChanged(NoteBlock block, bool checked) async {
    final Task? task = await _tasksDao.getTaskForBlock(block.id);
    if (task != null && task.isCompleted != checked) {
      await _tasksDao.updateTask(
          TasksCompanion(id: Value(task.id), isCompleted: Value(checked)));
    }
  }

  /// Mirrors a task's completion back onto its source note checkbox (if the
  /// task came from a note). No-op for ordinary tasks.
  Future<void> mirrorTaskCompletionToBlock(
      int taskId, bool isCompleted) async {
    final Task? task = await _tasksDao.getTask(taskId);
    final int? blockId = task?.sourceNoteBlockId;
    if (blockId == null) return;

    final NoteBlock? block = await _notesDao.getBlock(blockId);
    if (block == null || block.checked == isCompleted) return;

    await _notesDao.setBlockChecked(blockId, isCompleted);
    await _notesDao.touchNote(block.noteId, DateTime.now());
  }

  /// Finds the note's backing list (by identity) or creates it, keeping its
  /// name in step with the note's title.
  Future<int> _ensureNoteList(
      int noteId, String noteTitle, DateTime now) async {
    final String name = noteTitle.isNotEmpty ? noteTitle : 'Note tasks';
    final TaskList? existing = await _listsDao.getListForNote(noteId);
    if (existing != null) {
      if (existing.name != name) {
        await _listsDao.updateList(
            TaskListsCompanion(id: Value(existing.id), name: Value(name)));
      }
      return existing.id;
    }
    return _listsDao.insertList(TaskListsCompanion.insert(
      name: name,
      createdAt: now,
      sourceNoteId: Value(noteId),
    ));
  }
}
