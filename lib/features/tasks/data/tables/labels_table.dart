import 'package:drift/drift.dart';

import 'tasks_table.dart';

/// Cross-cutting tag. Many-to-many with tasks via [TaskLabels].
class Labels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFFA6ABEC))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
}

/// Junction: which labels a task carries. CASCADE both ways.
class TaskLabels extends Table {
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get labelId =>
      integer().references(Labels, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {taskId, labelId};
}
