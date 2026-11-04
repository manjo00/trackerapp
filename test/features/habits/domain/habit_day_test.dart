import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/habits/domain/habit_day.dart';

void main() {
  group('habitDayOf', () {
    test('a moment before 04:00 counts for the day before', () {
      expect(habitDayOf(DateTime(2026, 11, 5, 2, 30)), '2026-11-04');
      expect(habitDayOf(DateTime(2026, 11, 5, 3, 59)), '2026-11-04');
    });

    test('the new day starts at 04:00', () {
      expect(habitDayOf(DateTime(2026, 11, 5, 4)), '2026-11-05');
    });

    test('a day start of 0 means midnight', () {
      expect(habitDayOf(DateTime(2026, 11, 5), dayStartMinutes: 0),
          '2026-11-05');
    });
  });

  test('weekStartOf follows the week-start setting', () {
    expect(weekStartOf('2026-11-04', weekStartsSunday: true), '2026-11-01');
    expect(weekStartOf('2026-11-04', weekStartsSunday: false), '2026-11-02');
    expect(weekStartOf('2026-11-01', weekStartsSunday: true), '2026-11-01');
    expect(weekStartOf('2026-11-01', weekStartsSunday: false), '2026-10-26');
  });

  test('addDays crosses months and years', () {
    expect(addDays('2026-12-31', 1), '2027-01-01');
    expect(addDays('2026-11-04', -400), '2025-09-30');
  });

  test('dayKey writes the calendar date', () {
    expect(dayKey(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
  });
}
