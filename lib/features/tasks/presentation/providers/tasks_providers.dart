import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../data/dao/tasks_dao.dart';
import '../../data/models/task_model.dart';
import '../../data/models/task_priority.dart';
import '../../data/repositories/tasks_repository.dart';

part 'tasks_providers.g.dart';

// ── Repository ────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
TasksRepository tasksRepository(TasksRepositoryRef ref) {
  final dao = TasksDao(ref.watch(appDatabaseProvider));
  return TasksRepository(dao);
}

// ── Read providers ────────────────────────────────────────────────────────

/// Stream of all tasks (sorted by completion, due date, priority).
@riverpod
Stream<List<TaskModel>> allTasks(AllTasksRef ref) {
  return ref.watch(tasksRepositoryProvider).watchAllTasks();
}

/// Stream of incomplete tasks due today — used by [TodayScreen].
@riverpod
Stream<List<TaskModel>> tasksDueToday(TasksDueTodayRef ref) {
  return ref.watch(tasksRepositoryProvider).watchTasksDueToday();
}

/// Stream of incomplete tasks past their due date — shown in Today's
/// "Overdue" section so nothing slips through.
@riverpod
Stream<List<TaskModel>> overdueTasks(OverdueTasksRef ref) {
  return ref.watch(tasksRepositoryProvider).watchOverdueTasks();
}

/// Incomplete tasks not filed under any list — Home's "Captured" block.
@riverpod
Stream<List<TaskModel>> capturedTasks(CapturedTasksRef ref) {
  return ref.watch(tasksRepositoryProvider).watchCapturedTasks();
}

// ── Write providers ───────────────────────────────────────────────────────

/// Handles adding a new task.
///
/// Usage:
/// ```dart
/// await ref.read(addTaskProvider.notifier).add(
///   'Buy milk',
///   dueDate: '2026-05-28',
///   priority: TaskPriority.high,
/// );
/// ```
@riverpod
class AddTask extends _$AddTask {
  @override
  Future<void> build() async {}

  /// Adds a task and returns its new id (null if the insert failed).
  Future<int?> add(
    String title, {
    String? note,
    String? dueDate,
    String? dueTime,
    TaskPriority priority = TaskPriority.medium,
    bool reminderEnabled = false,
    String? reminderLeadTimes,
    int? listId,
    int? sectionId,
    int? durationMinutes,
  }) async {
    state = const AsyncLoading();
    int? newId;
    state = await AsyncValue.guard(() async {
      newId = await ref.read(tasksRepositoryProvider).addTask(
            title,
            note: note,
            dueDate: dueDate,
            dueTime: dueTime,
            priority: priority,
            reminderEnabled: reminderEnabled,
            reminderLeadTimes: reminderLeadTimes,
            listId: listId,
            sectionId: sectionId,
            durationMinutes: durationMinutes,
          );
    });
    return newId;
  }
}

/// Handles toggling a task's completion state.
@riverpod
class ToggleTask extends _$ToggleTask {
  @override
  Future<void> build() async {}

  Future<void> toggle(int id, {required bool currentlyCompleted}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(tasksRepositoryProvider).toggleTask(
            id,
            currentlyCompleted: currentlyCompleted,
          ),
    );
    // Marking a task complete → cancel its pending notifications.
    // Marking incomplete → leave as-is; user can re-edit to set new reminders.
    if (!currentlyCompleted) {
      await NotificationService.instance.cancelTaskReminders(id);
    }
  }
}

/// Handles updating an existing task's editable fields.
@riverpod
class UpdateTask extends _$UpdateTask {
  @override
  Future<void> build() async {}

  Future<void> save(TaskModel task) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(tasksRepositoryProvider).updateTask(task),
    );
  }
}

/// Handles permanently deleting a task.
@riverpod
class DeleteTask extends _$DeleteTask {
  @override
  Future<void> build() async {}

  Future<void> delete(int taskId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(tasksRepositoryProvider).deleteTask(taskId),
    );
  }
}
