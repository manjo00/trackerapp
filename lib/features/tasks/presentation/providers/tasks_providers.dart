import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/database_provider.dart';
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

  Future<void> add(
    String title, {
    String? note,
    String? dueDate,
    TaskPriority priority = TaskPriority.medium,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(tasksRepositoryProvider).addTask(
            title,
            note: note,
            dueDate: dueDate,
            priority: priority,
          ),
    );
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
  }
}
