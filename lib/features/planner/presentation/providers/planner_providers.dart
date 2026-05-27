import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../habits/data/models/habit_with_status.dart';
import '../../../habits/presentation/providers/habits_providers.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/providers/tasks_providers.dart';

// ── DotSummary ────────────────────────────────────────────────────────────────

/// Aggregated data for a single calendar day — drives the dot indicators
/// shown in each column of the week strip.
class DotSummary {
  const DotSummary({
    required this.habitsTotal,
    required this.habitsDone,
    required this.tasksDue,
    required this.tasksCompleted,
  });

  final int habitsTotal;
  final int habitsDone;
  final int tasksDue;
  final int tasksCompleted;

  bool get hasAnyData => habitsTotal > 0 || tasksDue > 0;
}

// ── Provider family: habits for a specific date ───────────────────────────────

/// Emits the list of habits with their done/undone status for [date].
///
/// Written as a manual [StreamProvider.family] (no riverpod_generator) so the
/// planner can be added without re-running build_runner.
///
/// Usage: `ref.watch(habitsForDateProvider('2026-05-27'))`
final habitsForDateProvider =
    StreamProvider.family<List<HabitWithStatus>, String>(
  (ref, date) =>
      ref.watch(habitsRepositoryProvider).watchHabitsForDate(date),
);

// ── Provider family: tasks for a specific date ────────────────────────────────

/// Emits all tasks whose due date matches [date].
///
/// Usage: `ref.watch(tasksForDateProvider('2026-05-27'))`
final tasksForDateProvider =
    StreamProvider.family<List<TaskModel>, String>(
  (ref, date) =>
      ref.watch(tasksRepositoryProvider).watchTasksForDate(date),
);

// ── Provider family: dot summary for a day ────────────────────────────────────

/// Synchronously combines [habitsForDateProvider] and [tasksForDateProvider]
/// into a single [DotSummary] for one day.
///
/// Returns `null` while either underlying stream is still loading.
/// [DayColumn] uses this to render the compact dot indicators without
/// each column managing its own async lifecycle.
final dayDotSummaryProvider = Provider.family<DotSummary?, String>(
  (ref, date) {
    final habitsAsync = ref.watch(habitsForDateProvider(date));
    final tasksAsync = ref.watch(tasksForDateProvider(date));

    final List<HabitWithStatus>? habits = habitsAsync.valueOrNull;
    final List<TaskModel>? tasks = tasksAsync.valueOrNull;

    if (habits == null || tasks == null) return null;

    return DotSummary(
      habitsTotal: habits.length,
      habitsDone: habits.where((h) => h.isDoneToday).length,
      tasksDue: tasks.length,
      tasksCompleted: tasks.where((t) => t.isCompleted).length,
    );
  },
);
