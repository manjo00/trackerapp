import 'package:drift/drift.dart';

import '../../../notes/data/tables/notes_table.dart';

/// A user-created container of tasks ("List" is a placeholder noun —
/// see kListNoun). No row exists for Captured: tasks.listId NULL = captured.
class TaskLists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF8AB4F8))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  /// When set, the list is archived — hidden from active views but
  /// recoverable from the Archived screen. NULL = active. Its tasks stay
  /// (they show as "no list"/Captured) until the list is restored.
  DateTimeColumn get archivedAt => dateTime().nullable()();

  /// Set when this list was auto-created to hold a note's "@time" tasks. Points
  /// at the owning [Notes] row; ON DELETE CASCADE removes the list when the
  /// note is deleted. NULL = an ordinary, user-made list.
  IntColumn get sourceNoteId =>
      integer().nullable().references(Notes, #id, onDelete: KeyAction.cascade)();
}

/// Named group inside a list (e.g. "Planning" / "Buying" / "Doing").
class ListSections extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get listId =>
      integer().references(TaskLists, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
}
