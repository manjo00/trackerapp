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

  /// Incomplete tasks whose due date is in the past.
  /// Used by the Today screen's "Overdue" section.
  Stream<List<TaskModel>> watchOverdueTasks() {
    final String today = _dateStr(DateTime.now());
    return _dao.watchOverdueTasks(today).map(
          (rows) => rows.map(_fromRow).toList(),
        );
  }

  /// Incomplete tasks not filed under any list — Home's "Captured" block.
  Stream<List<TaskModel>> watchCapturedTasks() {
    return _dao.watchCapturedTasks().map(
          (rows) => rows.map(_fromRow).toList(),
        );
  }

  /// All tasks in one list (incomplete first, grouped by section).
  Stream<List<TaskModel>> watchTasksForList(int listId) {
    return _dao.watchTasksForList(listId).map(
          (rows) => rows.map(_fromRow).toList(),
        );
  }

  /// Incomplete tasks due between [from] and [to] inclusive ("yyyy-MM-dd").
  Stream<List<TaskModel>> watchTasksInRange(String from, String to) {
    return _dao.watchTasksInRange(from, to).map(
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

  /// Creates a new task and returns its auto-assigned id.
  Future<int> addTask(
    String title, {
    String? note,
    String? dueDate,
    String? dueTime,
    TaskPriority priority = TaskPriority.medium,
    bool reminderEnabled = false,
    String? reminderLeadTimes,
    int? listId,
    int? sectionId,
  }) {
    return _dao.insertTask(
      TasksCompanion(
        title: Value(title.trim()),
        note: Value(note?.trim()),
        dueDate: Value(dueDate),
        dueTime: Value(dueTime),
        priority: Value(priority.toInt()),
        createdAt: Value(DateTime.now()),
        reminderEnabled: Value(reminderEnabled),
        reminderLeadTimes: Value(reminderLeadTimes),
        listId: Value(listId),
        sectionId: Value(sectionId),
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

  /// Updates an existing task's editable fields (title, note, due date,
  /// due time, priority, and reminder settings).
  Future<void> updateTask(TaskModel task) async {
    await _dao.updateTask(
      TasksCompanion(
        id: Value(task.id),
        title: Value(task.title.trim()),
        note: Value(task.note?.trim()),
        dueDate: Value(task.dueDate),
        dueTime: Value(task.dueTime),
        priority: Value(task.priority.toInt()),
        reminderEnabled: Value(task.reminderEnabled),
        reminderLeadTimes: Value(task.reminderLeadTimes),
        listId: Value(task.listId),
        sectionId: Value(task.sectionId),
      ),
    );
  }

  /// Returns all tasks as a one-shot list (used by rescheduleAll in app.dart).
  Future<List<TaskModel>> getAllTasks() async {
    final rows = await _dao.getAllTasks();
    return rows.map(_fromRow).toList();
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
        dueTime: row.dueTime,
        priority: TaskPriority.fromInt(row.priority),
        isCompleted: row.isCompleted,
        createdAt: row.createdAt,
        reminderEnabled: row.reminderEnabled,
        reminderLeadTimes: row.reminderLeadTimes,
        listId: row.listId,
        sectionId: row.sectionId,
      );
}
