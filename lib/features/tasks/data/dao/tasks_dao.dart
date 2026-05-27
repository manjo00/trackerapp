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
            (t) => t.dueDate.equals(today) & t.isCompleted.equals(false),
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
          ..where((t) => t.dueDate.equals(date))
          ..orderBy([
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.desc(t.priority),
          ]))
        .watch();
  }

  /// All tasks as a one-shot list (used by rescheduleAll on app start).
  Future<List<Task>> getAllTasks() => select(tasks).get();

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
