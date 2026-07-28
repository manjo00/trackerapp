import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../tables/tasks_table.dart';

part 'tasks_dao.g.dart';

/// All database queries for the tasks feature.
@DriftAccessor(tables: [Tasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db);

  // ── Streams ───────────────────────────────────────────────────────────────

  /// All tasks: incomplete first, then by due date ascending (nulls last),
  /// then by priority descending (high first).
  ///
  /// Drift can only express simple ORDER BY in the query builder, so we
  /// order by isCompleted and createdAt here; the repository's [sortTasks()]
  /// handles the full sort including null due-date handling.
  Stream<List<Task>> watchAllTasks() {
    return (select(tasks)
          ..where((t) => t.archivedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.desc(t.priority),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch();
  }

  /// Tasks that are due today and not yet completed.
  /// [today] must be in "yyyy-MM-dd" format.
  Stream<List<Task>> watchTasksDueToday(String today) {
    return (select(tasks)
          ..where(
            (t) =>
                t.dueDate.equals(today) &
                t.isCompleted.equals(false) &
                t.archivedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.priority)]))
        .watch();
  }

  /// Incomplete tasks whose due date is strictly before [today].
  /// [today] must be in "yyyy-MM-dd" format.
  /// Ordered by due date ascending (most overdue first) then priority desc.
  Stream<List<Task>> watchOverdueTasks(String today) {
    return (select(tasks)
          ..where(
            (t) =>
                t.dueDate.isNotNull() &
                t.isCompleted.equals(false) &
                t.archivedAt.isNull() &
                t.dueDate.isSmallerThanValue(today),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.dueDate),
            (t) => OrderingTerm.desc(t.priority),
          ]))
        .watch();
  }

  /// All tasks due on [date] (any completion state), ordered by
  /// completion ascending (incomplete first) then priority descending.
  Stream<List<Task>> watchTasksForDate(String date) {
    return (select(tasks)
          ..where((t) => t.dueDate.equals(date) & t.archivedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.desc(t.priority),
          ]))
        .watch();
  }

  /// Incomplete tasks not filed under any list — "Captured".
  /// (No Inbox row exists by design: listId NULL *is* the inbox.)
  Stream<List<Task>> watchCapturedTasks() {
    return (select(tasks)
          ..where((t) =>
              t.listId.isNull() &
              t.isCompleted.equals(false) &
              t.archivedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.priority),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch();
  }

  /// All tasks in one list: incomplete first, grouped by section
  /// (unsectioned tasks first — SQLite sorts NULL first on ASC), then
  /// priority descending within a section.
  Stream<List<Task>> watchTasksForList(int listId) {
    return (select(tasks)
          ..where((t) => t.listId.equals(listId) & t.archivedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.asc(t.sectionId),
            (t) => OrderingTerm.desc(t.priority),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch();
  }

  /// Incomplete tasks due between [from] and [to] inclusive
  /// ("yyyy-MM-dd" strings) — feeds Home's "This week" strip.
  Stream<List<Task>> watchTasksInRange(String from, String to) {
    return (select(tasks)
          ..where((t) =>
              t.isCompleted.equals(false) &
              t.archivedAt.isNull() &
              t.dueDate.isBetweenValues(from, to))
          ..orderBy([
            (t) => OrderingTerm.asc(t.dueDate),
            (t) => OrderingTerm.desc(t.priority),
          ]))
        .watch();
  }

  /// Active tasks as a one-shot list (used by rescheduleAll on app start).
  /// Archived tasks are excluded so their reminders don't get rescheduled.
  Future<List<Task>> getAllTasks() =>
      (select(tasks)..where((t) => t.archivedAt.isNull())).get();

  /// Archived tasks, most-recently-archived first (Archived screen).
  Stream<List<Task>> watchArchivedTasks() {
    return (select(tasks)
          ..where((t) => t.archivedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.archivedAt)]))
        .watch();
  }

  /// Sets/clears a task's archived state ([at] = null unarchives).
  Future<void> setTaskArchived(int taskId, DateTime? at) =>
      (update(tasks)..where((t) => t.id.equals(taskId)))
          .write(TasksCompanion(archivedAt: Value(at)));

  /// One-shot fetch of a single task by id (null if it doesn't exist).
  Future<Task?> getTask(int id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// The task auto-created from a given note block, if any. Used by the
  /// note→task linker to decide whether to create, update, or delete it.
  Future<Task?> getTaskForBlock(int blockId) =>
      (select(tasks)..where((t) => t.sourceNoteBlockId.equals(blockId)))
          .getSingleOrNull();

  // ── Writes ────────────────────────────────────────────────────────────────

  /// Inserts a new task row and returns its auto-assigned id.
  Future<int> insertTask(TasksCompanion companion) =>
      into(tasks).insert(companion);

  /// Updates specific fields on an existing task row.
  /// Used to toggle [isCompleted].
  Future<void> updateTask(TasksCompanion companion) =>
      (update(tasks)..where((t) => t.id.equals(companion.id.value)))
          .write(companion);

  /// Permanently deletes a task by id.
  Future<int> deleteTask(int taskId) =>
      (delete(tasks)..where((t) => t.id.equals(taskId))).go();
}
