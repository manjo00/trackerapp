import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/dao/lists_dao.dart';
import '../../data/dao/tasks_dao.dart';
import '../../data/models/task_model.dart';
import '../../data/models/task_priority.dart';
import '../../data/repositories/lists_repository.dart';
import 'tasks_providers.dart';

final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');
String _dateStr(DateTime dt) => _dateFmt.format(dt);

// ── Data layer ────────────────────────────────────────────────────────────

final listsDaoProvider =
    Provider<ListsDao>((ref) => ListsDao(ref.watch(appDatabaseProvider)));

final listsRepositoryProvider = Provider<ListsRepository>((ref) =>
    ListsRepository(
        ref.watch(listsDaoProvider), TasksDao(ref.watch(appDatabaseProvider))));

// ── Lists / sections / labels streams ─────────────────────────────────────

final taskListsProvider = StreamProvider<List<TaskList>>(
    (ref) => ref.watch(listsRepositoryProvider).watchLists());

/// Incomplete-task count per list id (missing key = 0).
final listTaskCountsProvider = StreamProvider<Map<int, int>>(
    (ref) => ref.watch(listsRepositoryProvider).watchTaskCountsByList());

final sectionsForListProvider =
    StreamProvider.family<List<ListSection>, int>((ref, listId) =>
        ref.watch(listsRepositoryProvider).watchSections(listId));

final tasksForListProvider = StreamProvider.family<List<TaskModel>, int>(
    (ref, listId) =>
        ref.watch(tasksRepositoryProvider).watchTasksForList(listId));

final labelsProvider = StreamProvider<List<Label>>(
    (ref) => ref.watch(listsRepositoryProvider).watchLabels());

final labelIdsForTaskProvider = StreamProvider.family<List<int>, int>(
    (ref, taskId) =>
        ref.watch(listsRepositoryProvider).watchLabelIdsForTask(taskId));

// ── Home blocks ───────────────────────────────────────────────────────────
//
// Date-anchored: app.dart invalidates these on resume (like the other
// date-sensitive providers) so "today" never goes stale overnight.

/// Incomplete tasks due today or tomorrow — the urgency window that,
/// combined with overdue, feeds [urgentTasksProvider].
final urgentWindowTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final DateTime now = DateTime.now();
  return ref.watch(tasksRepositoryProvider).watchTasksInRange(
      _dateStr(now), _dateStr(now.add(const Duration(days: 1))));
});

/// Home's "Urgent" block: overdue ∪ high-priority due today/tomorrow,
/// de-duped by id, most urgent (earliest due date) first.
final urgentTasksProvider = Provider<List<TaskModel>>((ref) {
  final List<TaskModel> overdue =
      ref.watch(overdueTasksProvider).valueOrNull ?? const [];
  final List<TaskModel> window =
      ref.watch(urgentWindowTasksProvider).valueOrNull ?? const [];

  final Map<int, TaskModel> byId = {for (final t in overdue) t.id: t};
  for (final TaskModel t in window) {
    if (t.priority == TaskPriority.high) byId.putIfAbsent(t.id, () => t);
  }
  final List<TaskModel> merged = byId.values.toList()
    ..sort((a, b) => (a.dueDate ?? '9999').compareTo(b.dueDate ?? '9999'));
  return merged;
});

/// Home's "This week" strip: incomplete tasks due within the next 7 days
/// (today inclusive), ordered by due date. Grouped per-day in the UI.
final thisWeekTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final DateTime now = DateTime.now();
  return ref.watch(tasksRepositoryProvider).watchTasksInRange(
      _dateStr(now), _dateStr(now.add(const Duration(days: 6))));
});
