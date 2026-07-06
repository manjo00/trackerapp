import '../../../core/utils/time_block_utils.dart';
import '../../tasks/data/models/task_model.dart';

/// Pure geometry for the Planner's 24-hour day grid — kept free of widgets
/// so the overlap/column logic is unit-testable (it breaks silently
/// otherwise).

/// One positioned slab on the grid.
class DayGridItem {
  const DayGridItem({
    required this.task,
    required this.startMin,
    required this.durationMin,
    required this.column,
    required this.columns,
  });

  final TaskModel task;

  /// Minutes since midnight.
  final int startMin;

  /// Block length; tasks with a time but no duration render as 30 min.
  final int durationMin;

  /// Which side-by-side column this slab occupies (0-based)…
  final int column;

  /// …out of how many in its overlap cluster (capped at 3; a 4th
  /// overlapping item wraps back onto column 0 and stacks visually).
  final int columns;
}

/// Positions every timed task for the grid. Untimed tasks are excluded
/// (they live in the "Anytime" strip). Touching ranges (10:00–11:00 and
/// 11:00–12:00) do NOT count as overlapping.
List<DayGridItem> layoutDayItems(List<TaskModel> tasks) {
  // (startMin, durationMin, task), sorted by start then id for stability.
  final List<(int, int, TaskModel)> timed = [
    for (final t in tasks)
      if (minutesOfDay(t.dueTime) != null)
        (
          minutesOfDay(t.dueTime) ?? 0,
          t.durationMinutes ?? 30,
          t,
        ),
  ]..sort((a, b) =>
      a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$3.id.compareTo(b.$3.id));

  // Group into overlap clusters: a cluster extends while the next item
  // starts before the furthest end seen so far.
  final List<DayGridItem> result = [];
  int i = 0;
  while (i < timed.length) {
    int clusterEnd = timed[i].$1 + timed[i].$2;
    int j = i + 1;
    while (j < timed.length && timed[j].$1 < clusterEnd) {
      final int end = timed[j].$1 + timed[j].$2;
      if (end > clusterEnd) clusterEnd = end;
      j++;
    }
    final int clusterSize = j - i;
    final int columns = clusterSize > 3 ? 3 : clusterSize;
    for (int k = i; k < j; k++) {
      result.add(DayGridItem(
        task: timed[k].$3,
        startMin: timed[k].$1,
        durationMin: timed[k].$2,
        column: (k - i) % columns,
        columns: columns,
      ));
    }
    i = j;
  }
  return result;
}

/// Splits a day's tasks for the LIST view: timed (sorted by start time)
/// and untimed (urgency: priority desc, then oldest first).
(List<TaskModel>, List<TaskModel>) splitTimed(List<TaskModel> tasks) {
  final List<TaskModel> timed = tasks
      .where((t) => minutesOfDay(t.dueTime) != null)
      .toList()
    ..sort((a, b) => (minutesOfDay(a.dueTime) ?? 0)
        .compareTo(minutesOfDay(b.dueTime) ?? 0));
  final List<TaskModel> untimed = tasks
      .where((t) => minutesOfDay(t.dueTime) == null)
      .toList()
    ..sort((a, b) {
      final int p = b.priority.toInt().compareTo(a.priority.toInt());
      return p != 0 ? p : a.createdAt.compareTo(b.createdAt);
    });
  return (timed, untimed);
}
