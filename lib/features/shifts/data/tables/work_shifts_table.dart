import 'package:drift/drift.dart';

/// Defines the [work_shifts] table — one row per working day.
///
/// A "shift" marks a calendar day as a work day of a given type (day/night).
/// Days the user is OFF simply have no row — absence means "free".
///
/// The [uniqueKeys] override puts a UNIQUE constraint on [date], so a day can
/// hold at most one shift. Re-assigning a day is a delete-then-insert in the
/// repository (mirrors the trackers' logChecklist pattern).
class WorkShifts extends Table {
  /// Unique row identifier — auto-assigned by SQLite on insert.
  IntColumn get id => integer().autoIncrement()();

  /// The calendar day this shift falls on, stored as "yyyy-MM-dd".
  TextColumn get date => text().withLength(min: 10, max: 10)();

  /// Which kind of shift: 'day' or 'night'. Maps to the [ShiftType] enum.
  TextColumn get shiftType => text()();

  /// Shift start time as "HH:mm" (e.g. "07:00"). Defaults come from the
  /// shift type but are stored per-row so a single day can be overridden later.
  TextColumn get startTime => text()();

  /// Shift end time as "HH:mm" (e.g. "19:00"). For night shifts this is the
  /// next morning — spanning is a rendering concern, not stored here.
  TextColumn get endTime => text()();

  /// One shift per calendar day.
  @override
  List<Set<Column>> get uniqueKeys => [
        {date},
      ];
}
