import 'package:drift/drift.dart';

/// Defines the [tasks] table in SQLite.
///
/// Unlike habits (which track daily completions in a second table),
/// a task is a one-time item: it's either done or not.  The [isCompleted]
/// flag lives directly on this row — no companion table needed.
///
/// Priority is stored as an INTEGER (0 = low, 1 = medium, 2 = high) so
/// it can be sorted numerically.  The [TaskPriority] enum in
/// `task_priority.dart` maps between Dart and these integer values.
class Tasks extends Table {
  /// Unique row identifier — auto-assigned by SQLite on insert.
  IntColumn get id => integer().autoIncrement()();

  /// The task title, e.g. "Buy groceries".
  TextColumn get title => text().withLength(min: 1, max: 200)();

  /// Optional longer description or note for this task.
  TextColumn get note => text().nullable()();

  /// Optional due date stored as "yyyy-MM-dd" (e.g. "2026-05-27").
  /// NULL means no due date set.
  TextColumn get dueDate => text().nullable()();

  /// Priority level: 0 = low, 1 = medium, 2 = high.
  /// Default is medium (1) so new tasks are visible but not urgent.
  IntColumn get priority => integer().withDefault(const Constant(1))();

  /// Whether the task has been completed.
  /// Stored as 0 (false) or 1 (true) in SQLite.
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  /// When this task was created (UTC).
  DateTimeColumn get createdAt => dateTime()();
}
