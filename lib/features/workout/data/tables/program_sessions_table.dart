import 'package:drift/drift.dart';
import 'programs_table.dart';

/// A named session type within a [Programs] row, e.g. "Push", "Pull", "Legs".
///
/// For rotating splits this acts as a slot in the cycle (ordered by [orderIndex]).
/// For weekly splits, [weekDays] stores which ISO weekdays the session falls on.
class ProgramSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The program this session type belongs to.
  IntColumn get programId => integer().references(
        Programs,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// Display name, e.g. "Push", "Pull A", "Upper Body".
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// ARGB color integer used for the session badge chip.
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF6750A4))();

  /// Position within the program's rotation (0-based).
  IntColumn get orderIndex =>
      integer().withDefault(const Constant(0))();

  /// For weekly splits: comma-separated ISO weekday numbers (Mon=1, Sun=7).
  /// e.g. "1,4" means Monday and Thursday.
  /// NULL for rotating splits.
  TextColumn get weekDays => text().nullable()();
}
