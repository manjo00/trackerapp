import 'package:drift/drift.dart' show Value;
import '../../../../core/database/app_database.dart';
import '../dao/shifts_dao.dart';
import '../models/work_shift_model.dart';

/// Provides all work-shift operations to the presentation layer.
///
/// The key method is [watchShiftsByDate], which exposes shifts as a map keyed
/// by "yyyy-MM-dd". This map is the single source of truth that every calendar
/// surface (Planner, date-picker, Today tiles) reads from.
class ShiftsRepository {
  ShiftsRepository(this._dao);

  final ShiftsDao _dao;

  // ── Streams ───────────────────────────────────────────────────────────────

  /// All shifts as a date-keyed map for O(1) lookup: `map["2026-07-03"]`.
  Stream<Map<String, WorkShiftModel>> watchShiftsByDate() {
    return _dao.watchAllShifts().map((rows) {
      final Map<String, WorkShiftModel> byDate = {};
      for (final WorkShift row in rows) {
        byDate[row.date] = _fromRow(row);
      }
      return byDate;
    });
  }

  // ── Write operations ──────────────────────────────────────────────────────

  /// Sets [date] to a shift of [type], replacing any existing shift that day.
  ///
  /// When [startTime]/[endTime] are omitted, the type's default hours are used
  /// (Day 07:00–19:00, Night 19:00–07:00).
  Future<void> setShift(
    String date,
    ShiftType type, {
    String? startTime,
    String? endTime,
    String? rotationLabel,
    int? rotationColor,
  }) async {
    // One shift per day — clear any existing row first (delete-then-insert).
    await _dao.deleteShiftForDate(date);
    await _dao.insertShift(
      WorkShiftsCompanion(
        date: Value(date),
        shiftType: Value(type.value),
        startTime: Value(startTime ?? type.defaultStart),
        endTime: Value(endTime ?? type.defaultEnd),
        rotationLabel: Value(rotationLabel),
        rotationColor: Value(rotationColor),
      ),
    );
  }

  // ── Rotations ───────────────────────────────────────────────────────────────

  Stream<List<ShiftRotationModel>> watchRotations() =>
      _dao.watchRotations().map(
            (rows) => rows.map(_rotationFromRow).toList(),
          );

  Future<void> addRotation(String name, int colorValue) async {
    final existing = await _dao.getRotations();
    await _dao.insertRotation(ShiftRotationsCompanion(
      name: Value(name.trim()),
      colorValue: Value(colorValue),
      orderIndex: Value(existing.length),
    ));
  }

  Future<void> updateRotation(ShiftRotationModel rotation) =>
      _dao.updateRotation(ShiftRotationsCompanion(
        id: Value(rotation.id),
        name: Value(rotation.name.trim()),
        colorValue: Value(rotation.colorValue),
        orderIndex: Value(rotation.orderIndex),
      ));

  Future<void> deleteRotation(int id) => _dao.deleteRotation(id);

  ShiftRotationModel _rotationFromRow(ShiftRotation row) => ShiftRotationModel(
        id: row.id,
        name: row.name,
        colorValue: row.colorValue,
        orderIndex: row.orderIndex,
      );

  /// Marks [date] as OFF by removing its shift row.
  Future<void> clearShift(String date) => _dao.deleteShiftForDate(date);

  // ── Private converter ─────────────────────────────────────────────────────

  WorkShiftModel _fromRow(WorkShift row) => WorkShiftModel(
        id: row.id,
        date: row.date,
        type: ShiftType.fromString(row.shiftType),
        startTime: row.startTime,
        endTime: row.endTime,
        rotationLabel: row.rotationLabel,
        rotationColor: row.rotationColor,
      );
}
