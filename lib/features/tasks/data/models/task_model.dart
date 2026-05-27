import 'package:freezed_annotation/freezed_annotation.dart';
import 'task_priority.dart';

part 'task_model.freezed.dart';

/// Immutable domain representation of a single task.
///
/// Produced by [TasksRepository] from a raw Drift [Task] row.
/// All UI code works with this type — never with Drift's generated row class.
@freezed
abstract class TaskModel with _$TaskModel {
  const factory TaskModel({
    required int id,
    required String title,
    String? note,
    /// Due date as "yyyy-MM-dd", or null if no due date is set.
    String? dueDate,
    /// Optional due time as "HH:mm", e.g. "14:30". When null, "09:00"
    /// is used as the default for notification scheduling.
    String? dueTime,
    required TaskPriority priority,
    required bool isCompleted,
    required DateTime createdAt,
    /// Whether reminder notifications are enabled for this task.
    @Default(false) bool reminderEnabled,
    /// Comma-separated lead-time intervals in minutes, e.g. "1440,180,5".
    /// Use [leadTimeMinutes] to access these as a typed list.
    String? reminderLeadTimes,
  }) = _TaskModel;

  // Private constructor required for custom getters in freezed classes.
  const TaskModel._();

  /// Parses [reminderLeadTimes] into a list of integers.
  ///
  /// Returns an empty list when [reminderLeadTimes] is null or empty.
  /// Example: "1440,180,5" → [1440, 180, 5]
  List<int> get leadTimeMinutes {
    if (reminderLeadTimes == null || reminderLeadTimes!.trim().isEmpty) {
      return const [];
    }
    return reminderLeadTimes!
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();
  }
}
