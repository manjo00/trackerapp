import '../../../core/database/app_database.dart';
import '../../../core/text/when_parser.dart';
import '../../habits/data/dao/habits_dao.dart';
import '../../notes/data/dao/notes_dao.dart';
import '../../notes/data/repositories/notes_repository.dart';
import '../../tasks/data/dao/lists_dao.dart';
import '../../tasks/data/dao/tasks_dao.dart';
import '../../trackers/data/dao/trackers_dao.dart';

/// How long an item waits in Recently deleted before it is really gone.
const Duration kTrashRetention = Duration(days: 30);

/// One place to archive / delete / restore anything the user can put away.
///
/// Every item moves through three states, and each one has a way back:
///
/// ```
/// active  ──archive──▶  archived  ──delete──▶  recently deleted  ──30d──▶  gone
///    ▲                      │                        │
///    └──────restore─────────┘                        │
///    └──────────────restore (back where it was)──────┘
/// ```
///
/// The whole design rests on one invariant: **`deletedAt` is never set without
/// `archivedAt`.** Deleting a live item stamps both with the same timestamp.
/// Because every active query in the app already filters `archivedAt IS NULL`,
/// a deleted row is invisible everywhere without a single active query being
/// touched — and the pair of stamps also records where the item came from, so
/// restore can put it back there (see [wasLiveWhenDeleted]).
///
/// Talks straight to the DAOs (which own the two columns) so the six features
/// don't each need parallel repo plumbing. [NotesRepository] is the exception:
/// destroying a note has to delete its photo FILES, not just its row.
class ArchiveService {
  ArchiveService(AppDatabase db, this._notesRepo)
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
  final NotesRepository _notesRepo;

  // `now` is always passed in rather than read here, so tests can inject a
  // fixed timestamp and assert on the exact stamps.

  /// True when the row was still live at the moment it was deleted — both
  /// stamps carry the same time. Deleting an item that had already been
  /// archived leaves an *earlier* [archivedAt], which is how restore knows to
  /// put it back in the archive instead of back into the app.
  static bool wasLiveWhenDeleted(DateTime? archivedAt, DateTime? deletedAt) {
    if (archivedAt == null || deletedAt == null) return false;
    return !archivedAt.isBefore(deletedAt);
  }

  /// Whole days left before [deletedAt] is purged. 0 means it goes today.
  static int daysLeftInTrash(DateTime deletedAt, DateTime now) {
    final int days = deletedAt.add(kTrashRetention).difference(now).inDays;
    return days < 0 ? 0 : days;
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  /// Archives a task. If it was auto-created from a note line, its `@token` is
  /// stripped from that line (which stays as a plain checkbox) so the note
  /// shows it's no longer an active task and won't respawn one.
  Future<void> archiveTask(int id, DateTime now) async {
    await _tasks.setTaskArchived(id, now);
    await _stripNoteTokenFor(id, now);
  }

  /// Brings a task back. If its list was archived or deleted meanwhile, that
  /// list comes back too — otherwise the task would return invisible.
  Future<void> restoreTask(int id) async {
    await _tasks.setTaskArchived(id, null);
    await _tasks.setTaskDeleted(id, null);
    final Task? task = await _tasks.getTask(id);
    final int? listId = task?.listId;
    if (listId != null) await _ensureListVisible(listId);
  }

  Future<void> trashTask(int id, DateTime now) async {
    final Task? task = await _tasks.getTask(id);
    if (task == null) return;
    if (task.archivedAt == null) await archiveTask(id, now);
    await _tasks.setTaskDeleted(id, now);
  }

  Future<void> restoreTaskFromTrash(int id) async {
    final Task? task = await _tasks.getTask(id);
    if (task == null) return;
    if (wasLiveWhenDeleted(task.archivedAt, task.deletedAt)) {
      await restoreTask(id);
    } else {
      await _tasks.setTaskDeleted(id, null);
    }
  }

  /// Removes a task for good. A note-linked task is removed by deleting its
  /// source note line (the DB cascade then removes the task too), so it
  /// disappears from both the task list and the note.
  Future<void> destroyTask(int id) async {
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

  // ── Lists ─────────────────────────────────────────────────────────────────

  Future<void> archiveList(int id, DateTime now) =>
      _lists.setListArchived(id, now);

  Future<void> restoreList(int id) async {
    await _lists.setListArchived(id, null);
    await _lists.setListDeleted(id, null);
  }

  Future<void> trashList(int id, DateTime now) async {
    final TaskList? list = await _lists.getList(id);
    if (list == null) return;
    if (list.archivedAt == null) await _lists.setListArchived(id, now);
    await _lists.setListDeleted(id, now);
  }

  Future<void> restoreListFromTrash(int id) async {
    final TaskList? list = await _lists.getList(id);
    if (list == null) return;
    if (wasLiveWhenDeleted(list.archivedAt, list.deletedAt)) {
      await restoreList(id);
    } else {
      await _lists.setListDeleted(id, null);
    }
  }

  Future<void> destroyList(int id) => _lists.deleteList(id);

  /// Makes sure a container list is reachable again before something inside it
  /// is restored into it.
  Future<void> _ensureListVisible(int listId) async {
    final TaskList? list = await _lists.getList(listId);
    if (list == null) return;
    if (list.deletedAt != null || list.archivedAt != null) {
      await restoreList(listId);
    }
  }

  // ── Habits ────────────────────────────────────────────────────────────────

  Future<void> archiveHabit(int id, DateTime now) =>
      _habits.setHabitArchived(id, now);

  Future<void> restoreHabit(int id) async {
    await _habits.setHabitArchived(id, null);
    await _habits.setHabitDeleted(id, null);
  }

  Future<void> trashHabit(int id, DateTime now) async {
    final Habit? habit = await _habits.getHabit(id);
    if (habit == null) return;
    if (habit.archivedAt == null) await _habits.setHabitArchived(id, now);
    await _habits.setHabitDeleted(id, now);
  }

  Future<void> restoreHabitFromTrash(int id) async {
    final Habit? habit = await _habits.getHabit(id);
    if (habit == null) return;
    if (wasLiveWhenDeleted(habit.archivedAt, habit.deletedAt)) {
      await restoreHabit(id);
    } else {
      await _habits.setHabitDeleted(id, null);
    }
  }

  Future<void> destroyHabit(int id) => _habits.deleteHabit(id);

  // ── Trackers ──────────────────────────────────────────────────────────────

  Future<void> archiveTracker(int id, DateTime now) =>
      _trackers.setTrackerArchived(id, now);

  Future<void> restoreTracker(int id) async {
    await _trackers.setTrackerArchived(id, null);
    await _trackers.setTrackerDeleted(id, null);
  }

  Future<void> trashTracker(int id, DateTime now) async {
    final CustomTracker? tracker = await _trackers.getTracker(id);
    if (tracker == null) return;
    if (tracker.archivedAt == null) {
      await _trackers.setTrackerArchived(id, now);
    }
    await _trackers.setTrackerDeleted(id, now);
  }

  Future<void> restoreTrackerFromTrash(int id) async {
    final CustomTracker? tracker = await _trackers.getTracker(id);
    if (tracker == null) return;
    if (wasLiveWhenDeleted(tracker.archivedAt, tracker.deletedAt)) {
      await restoreTracker(id);
    } else {
      await _trackers.setTrackerDeleted(id, null);
    }
  }

  Future<void> destroyTracker(int id) => _trackers.deleteTracker(id);

  // ── Notes ─────────────────────────────────────────────────────────────────

  Future<void> archiveNote(int id, DateTime now) =>
      _notes.setNoteArchived(id, now);

  /// Brings a note back. If its notebook was archived or deleted meanwhile,
  /// that notebook comes back too — otherwise the note would return invisible.
  Future<void> restoreNote(int id) async {
    await _notes.setNoteArchived(id, null);
    await _notes.setNoteDeleted(id, null);
    final Note? note = await _notes.getNote(id);
    final int? notebookId = note?.notebookId;
    if (notebookId != null) await _ensureNotebookVisible(notebookId);
  }

  Future<void> trashNote(int id, DateTime now) async {
    final Note? note = await _notes.getNote(id);
    if (note == null) return;
    if (note.archivedAt == null) await _notes.setNoteArchived(id, now);
    await _notes.setNoteDeleted(id, now);
  }

  Future<void> restoreNoteFromTrash(int id) async {
    final Note? note = await _notes.getNote(id);
    if (note == null) return;
    if (wasLiveWhenDeleted(note.archivedAt, note.deletedAt)) {
      await restoreNote(id);
    } else {
      await _notes.setNoteDeleted(id, null);
    }
  }

  /// Removes a note for good, photo files included.
  Future<void> destroyNote(int id) => _notesRepo.deleteNoteWithPhotos(id);

  // ── Notebooks ─────────────────────────────────────────────────────────────

  /// Archives a notebook **and the notes inside it**, all stamped with the same
  /// timestamp — so restoring brings back exactly the notes that went in
  /// together, and archiving a full notebook doesn't scatter its notes into
  /// Unfiled. Notes the user had already archived on their own keep their older
  /// stamp and stay archived after a restore.
  Future<void> archiveNotebook(int id, DateTime now) async {
    await _notes.archiveNotesInNotebook(id, now);
    await _notes.setNotebookArchived(id, now);
  }

  Future<void> restoreNotebook(int id) async {
    final Notebook? notebook = await _notes.getNotebook(id);
    if (notebook == null) return;
    final DateTime? stamp = notebook.archivedAt;
    await _notes.setNotebookArchived(id, null);
    await _notes.setNotebookDeleted(id, null);
    await _notes.setNotesDeletedInNotebook(id, null);
    if (stamp != null) await _notes.restoreNotesArchivedWith(id, stamp);
  }

  Future<void> trashNotebook(int id, DateTime now) async {
    final Notebook? notebook = await _notes.getNotebook(id);
    if (notebook == null) return;
    if (notebook.archivedAt == null) await archiveNotebook(id, now);
    await _notes.setNotesDeletedInNotebook(id, now);
    await _notes.setNotebookDeleted(id, now);
  }

  Future<void> restoreNotebookFromTrash(int id) async {
    final Notebook? notebook = await _notes.getNotebook(id);
    if (notebook == null) return;
    if (wasLiveWhenDeleted(notebook.archivedAt, notebook.deletedAt)) {
      await restoreNotebook(id);
    } else {
      await _notes.setNotebookDeleted(id, null);
      await _notes.setNotesDeletedInNotebook(id, null);
    }
  }

  /// Removes a notebook for good, taking the notes that were deleted alongside
  /// it (photo files included). Any note still active in it survives and falls
  /// back to Unfiled, as it always has.
  Future<void> destroyNotebook(int id) async {
    for (final Note note in await _notes.deletedNotesInNotebook(id)) {
      await _notesRepo.deleteNoteWithPhotos(note.id);
    }
    await _notes.deleteNotebook(id);
  }

  Future<void> _ensureNotebookVisible(int notebookId) async {
    final Notebook? notebook = await _notes.getNotebook(notebookId);
    if (notebook == null) return;
    if (notebook.deletedAt != null || notebook.archivedAt != null) {
      await restoreNotebook(notebookId);
    }
  }

  // ── Purging ───────────────────────────────────────────────────────────────

  /// Really removes everything whose 30 days are up. Called once on launch —
  /// a plain query, no background worker. Returns how many rows went.
  Future<int> purgeExpired(DateTime now) =>
      _purgeDeletedBefore(now.subtract(kTrashRetention));

  /// Empties Recently deleted right now, on the user's say-so.
  Future<int> emptyTrash(DateTime now) =>
      _purgeDeletedBefore(now.add(const Duration(days: 1)));

  Future<int> _purgeDeletedBefore(DateTime cutoff) async {
    int removed = 0;
    // Notes go first and one at a time: their photo FILES have to be deleted
    // before the rows are, since CASCADE takes the block rows that name them.
    for (final Note note in await _notes.notesDeletedBefore(cutoff)) {
      await _notesRepo.deleteNoteWithPhotos(note.id);
      removed++;
    }
    removed += await _notes.purgeNotebooksDeletedBefore(cutoff);
    removed += await _tasks.purgeTasksDeletedBefore(cutoff);
    removed += await _lists.purgeListsDeletedBefore(cutoff);
    removed += await _habits.purgeHabitsDeletedBefore(cutoff);
    removed += await _trackers.purgeTrackersDeletedBefore(cutoff);
    return removed;
  }
}
