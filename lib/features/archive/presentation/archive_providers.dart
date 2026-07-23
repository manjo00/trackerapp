import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/text/when_parser.dart';
import '../../habits/data/dao/habits_dao.dart';
import '../../notes/data/dao/notes_dao.dart';
import '../../tasks/data/dao/lists_dao.dart';
import '../../tasks/data/dao/tasks_dao.dart';
import '../../tasks/presentation/providers/lists_providers.dart';
import '../../trackers/data/dao/trackers_dao.dart';

/// One place to archive / restore / delete-forever any archivable item.
/// Talks straight to the DAOs (which own the archivedAt column) so the four
/// features don't each need parallel repo plumbing.
class ArchiveService {
  ArchiveService(AppDatabase db)
      : _tasks = TasksDao(db),
        _lists = ListsDao(db),
        _habits = HabitsDao(db),
        _trackers = TrackersDao(db),
        _notes = NotesDao(db);

  final TasksDao _tasks;
  final ListsDao _lists;
  final HabitsDao _habits;
  final TrackersDao _trackers;
  final NotesDao _notes;

  // Archive (stamp) / restore (clear). `now` is passed in so the caller
  // controls the timestamp (tests inject a fixed value).

  /// Archives a task. If it was auto-created from a note line, its `@token` is
  /// stripped from that line (which stays as a plain checkbox) so the note
  /// shows it's no longer an active task and won't respawn one.
  Future<void> archiveTask(int id, DateTime now) async {
    await _tasks.setTaskArchived(id, now);
    await _stripNoteTokenFor(id, now);
  }

  Future<void> restoreTask(int id) => _tasks.setTaskArchived(id, null);

  /// Deletes a task. A note-linked task is removed by deleting its source note
  /// line (the DB cascade then removes the task too), so it disappears from
  /// both the task list and the note.
  Future<void> deleteTask(int id) async {
    final Task? task = await _tasks.getTask(id);
    final int? blockId = task?.sourceNoteBlockId;
    if (blockId != null) {
      await _notes.deleteBlock(blockId);
    } else {
      await _tasks.deleteTask(id);
    }
  }

  /// Removes the `@token` prefix from a note-linked task's source line, leaving
  /// the plain title text. No-op for ordinary tasks.
  Future<void> _stripNoteTokenFor(int taskId, DateTime now) async {
    final Task? task = await _tasks.getTask(taskId);
    final int? blockId = task?.sourceNoteBlockId;
    if (blockId == null) return;
    final NoteBlock? block = await _notes.getBlock(blockId);
    if (block == null) return;
    final NoteWhen? parsed =
        WhenParser.parseNoteLine(block.content ?? '', now: now);
    if (parsed == null) return;
    await _notes.updateBlockContent(blockId, parsed.title);
    await _notes.touchNote(block.noteId, now);
  }

  Future<void> archiveList(int id, DateTime now) =>
      _lists.setListArchived(id, now);
  Future<void> restoreList(int id) => _lists.setListArchived(id, null);
  Future<void> deleteList(int id) => _lists.deleteList(id);

  Future<void> archiveHabit(int id, DateTime now) =>
      _habits.setHabitArchived(id, now);
  Future<void> restoreHabit(int id) => _habits.setHabitArchived(id, null);
  Future<void> deleteHabit(int id) => _habits.deleteHabit(id);

  Future<void> archiveTracker(int id, DateTime now) =>
      _trackers.setTrackerArchived(id, now);
  Future<void> restoreTracker(int id) => _trackers.setTrackerArchived(id, null);
  Future<void> deleteTracker(int id) => _trackers.deleteTracker(id);
}

final archiveServiceProvider = Provider<ArchiveService>(
    (ref) => ArchiveService(ref.watch(appDatabaseProvider)));

// ── Archived-item streams (feed the Archived screen) ───────────────────────

final _tasksDaoForArchiveProvider =
    Provider<TasksDao>((ref) => TasksDao(ref.watch(appDatabaseProvider)));
final _trackersDaoForArchiveProvider = Provider<TrackersDao>(
    (ref) => TrackersDao(ref.watch(appDatabaseProvider)));
final _habitsDaoForArchiveProvider =
    Provider<HabitsDao>((ref) => HabitsDao(ref.watch(appDatabaseProvider)));

final archivedTasksProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(_tasksDaoForArchiveProvider).watchArchivedTasks());
final archivedListsProvider = StreamProvider<List<TaskList>>(
    (ref) => ref.watch(listsDaoProvider).watchArchivedLists());
final archivedHabitsProvider = StreamProvider<List<Habit>>(
    (ref) => ref.watch(_habitsDaoForArchiveProvider).watchArchivedHabits());
final archivedTrackersProvider = StreamProvider<List<CustomTracker>>((ref) =>
    ref.watch(_trackersDaoForArchiveProvider).watchArchivedTrackers());
