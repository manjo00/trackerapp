import 'package:drift/drift.dart';

/// Defines the [habit_pauses] table: "Away" ranges that pause every habit.
///
/// A day inside a range is neither kept nor missed, so a trip never breaks a
/// streak. Dates are habit days in `yyyy-MM-dd`; both ends are included.
class HabitPauses extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The first paused day, e.g. "2026-11-08".
  TextColumn get startDate => text()();

  /// The last paused day (included).
  TextColumn get endDate => text()();

  DateTimeColumn get createdAt => dateTime()();
}
