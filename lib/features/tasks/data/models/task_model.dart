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
    String? dueDate,           // "yyyy-MM-dd" or null (no due date)
    required TaskPriority priority,
    required bool isCompleted,
    required DateTime createdAt,
  }) = _TaskModel;
}
