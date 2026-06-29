import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../tables/work_shifts_table.dart';

part 'shifts_dao.g.dart';

/// All database queries for the work-shift schedule feature.
@DriftAccessor(tables: [WorkShifts])
class ShiftsDao extends DatabaseAccessor<AppDatabase> with _$ShiftsDaoMixin {
  ShiftsDao(super.db);

  // ── Streams ───────────────────────────────────────────────────────────────

  /// All shifts ordered by date ascending. The repository turns this into a
  /// date-keyed map for O(1) lookup by any calendar surface.
  Stream<List<WorkShift>> watchAllShifts() =>
      (select(workShifts)..orderBy([(s) => OrderingTerm.asc(s.date)])).watch();

  /// One-shot fetch of the shift on [date] (or null if it's a free day).
  Future<WorkShift?> getShiftForDate(String date) =>
      (select(workShifts)..where((s) => s.date.equals(date)))
          .getSingleOrNull();

  /// One-shot fetch of every shift — used to build the month-grid widget.
  Future<List<WorkShift>> getAllShifts() => select(workShifts).get();

  // ── Writes ────────────────────────────────────────────────────────────────

  Future<int> insertShift(WorkShiftsCompanion companion) =>
      into(workShifts).insert(companion);

  /// Removes the shift on [date], if any. Used when cycling a day back to OFF.
  Future<void> deleteShiftForDate(String date) =>
      (delete(workShifts)..where((s) => s.date.equals(date))).go();
}
