import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/shifts/data/dao/shifts_dao.dart';
import 'package:life_tracker/features/shifts/data/models/work_shift_model.dart';
import 'package:life_tracker/features/shifts/data/repositories/shifts_repository.dart';

/// Tests for the work-shift schedule data layer.
///
/// These run against an in-memory SQLite database ([AppDatabase.forTesting]),
/// so nothing touches the real device DB and each test starts clean.
///
/// What they cover:
///   • ShiftType default times are correct (the "don't know times yet" promise)
///   • setShift persists with those defaults
///   • a day can only hold one shift (re-assigning replaces, never duplicates)
///   • clearShift returns a day to OFF
void main() {
  late AppDatabase db;
  late ShiftsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ShiftsRepository(ShiftsDao(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('ShiftType carries sensible default times', () {
    expect(ShiftType.day.defaultStart, '07:00');
    expect(ShiftType.day.defaultEnd, '19:00');
    expect(ShiftType.night.defaultStart, '19:00');
    expect(ShiftType.night.defaultEnd, '07:00');
  });

  test('setShift inserts a shift with the type default times', () async {
    await repo.setShift('2026-07-03', ShiftType.day);

    final Map<String, WorkShiftModel> map = await repo.watchShiftsByDate().first;
    final WorkShiftModel? shift = map['2026-07-03'];

    expect(shift, isNotNull);
    expect(shift!.type, ShiftType.day);
    expect(shift.startTime, '07:00');
    expect(shift.endTime, '19:00');
  });

  test('setShift replaces an existing shift on the same day (one per day)',
      () async {
    await repo.setShift('2026-07-03', ShiftType.day);
    await repo.setShift('2026-07-03', ShiftType.night);

    final Map<String, WorkShiftModel> map = await repo.watchShiftsByDate().first;

    expect(map.length, 1);
    expect(map['2026-07-03']!.type, ShiftType.night);
  });

  test('clearShift removes the day (back to OFF)', () async {
    await repo.setShift('2026-07-03', ShiftType.day);
    await repo.clearShift('2026-07-03');

    final Map<String, WorkShiftModel> map = await repo.watchShiftsByDate().first;

    expect(map.containsKey('2026-07-03'), isFalse);
  });
}
