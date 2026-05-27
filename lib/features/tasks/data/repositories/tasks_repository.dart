import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../dao/tasks_dao.dart';
import '../models/task_model.dart';
import '../models/task_priority.dart';

final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');
String _dateStr(DateTime dt) => _dateFmt.format(dt);

/// Provides all task-related operations to the presentation layer.
///
/// Mirrors [HabitsRepository] in structure:
///   - Converts raw Drift rows → [TaskModel]
///   - Exposes streams for the UI to watch
///   - Write operations are simple async methods
///   - [sortTasks] is a pure static function (easily unit-tested)
class TasksRepository {
  TasksRepository(this._dao);

  final TasksDao _dao;

  // ── Streams ───────────────────────────────────────────────────────────────

  /// All tasks, sorted by [sortTasks] ordering.
  Stream<List<TaskModel>> watchAllTasks() {
    return _dao.watchAllTasks().map(
          (rows) => sortTasks(rows.map(_fromRow).toList()),
        );
  }

  /// Incomplete tasks due today, sorted high → low priority.
  Stream<List<TaskModel>> watchTasksDueToday() {
    final String today = _dateStr(DateTime.now());
    return _dao.watchTasksDueToday(today).map(
          (rows) => rows.map(_fromRow).toList(),
        );
  }

  /// All tasks due on a specific [date], sorted by completion + priority.
  /// Used by the planner day-detail view.
  Stream<List<TaskModel>> watchTasksForDate(String date) {
    return _dao.watchTasksForDate(date).map(
          (rows) => rows.map(_fromRow).toList(),
        );
  }

  // ── Write operations ──────────────────────────────────────────────────────

  /// Creates a new task.
  Future<void> addTask(
    String title, {
    String? note,
    String? dueDate,
    TaskPriority priority = TaskPriority.medium,
  }) async {
    await _dao.insertTask(
      TasksCompanion(
        title: Value(title.trim()),
        note: Value(note?.trim()),
        dueDate: Value(dueDate),
        priority: Value(priority.toInt()),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  /// Toggles a task's completion state.
  Future<void> toggleTask(int id, {required bool currentlyCompleted}) async {
    await _dao.updateTask(
      TasksCompanion(
        id: Value(id),
        isCompleted: Value(!currentlyCompleted),
      ),
    );
  }

  /// Permanently deletes a task.
  Future<void> deleteTask(int id) => _dao.deleteTask(id);

  // ── Sort logic (pure static — unit-testable without a DB) ─────────────────

  /// Sorts [tasks] by:
  ///   1. Completion status — incomplete first
  ///   2. Due date — earliest first; tasks with no due date go last
  ///   3. Priority — high before medium before low
  ///   4. Created date — oldest first (stable tie-break)
  ///
  /// Returns a new list; does not mutate the input.
  static List<TaskModel> sortTasks(List<TaskModel> tasks) {
    final List<TaskModel> copy = List.of(tasks);
    copy.sort((TaskModel a, TaskModel b) {
      // 1. Incomplete before complete
      final int completedCmp =
          (a.isCompleted ? 1 : 0).compareTo(b.isCompleted ? 1 : 0);
      if (completedCmp != 0) return completedCmp;

      // 2. Due date ascending — null (no due date) sorts last
      final int dueCmp = _compareDueDates(a.dueDate, b.dueDate);
      if (dueCmp != 0) return dueCmp;

      // 3. Priority descending (high = 2 first)
      final int priorityCmp =
          b.priority.toInt().compareTo(a.priority.toInt());
      if (priorityCmp != 0) return priorityCmp;

      // 4. Created date ascending (oldest first)
      return a.createdAt.compareTo(b.createdAt);
    });
    return copy;
  }

  static int _compareDueDates(String? a, String? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;  // null sorts after real dates
    if (b == null) return -1;
    return a.compareTo(b);   // "yyyy-MM-dd" sorts lexicographically
  }

  // ── Private converter ─────────────────────────────────────────────────────

  TaskModel _fromRow(Task row) => TaskModel(
        id: row.id,
        title: row.title,
        note: row.note,
        dueDate: row.dueDate,
        priority: TaskPriority.fromInt(row.priority),
        isCompleted: row.isCompleted,
        createdAt: row.createdAt,
      );
}
