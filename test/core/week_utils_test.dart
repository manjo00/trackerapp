import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/utils/week_utils.dart';

void main() {
  // 2026-07-04 is a Saturday; 2026-07-05 a Sunday; 2026-07-06 a Monday.
  final DateTime sat = DateTime(2026, 7, 4);
  final DateTime sun = DateTime(2026, 7, 5);
  final DateTime mon = DateTime(2026, 7, 6);

  group('startOfWeek (Monday start)', () {
    test('Saturday belongs to the week of the previous Monday', () {
      expect(startOfWeek(sat, sundayStart: false), DateTime(2026, 6, 29));
    });
    test('Monday is its own week start', () {
      expect(startOfWeek(mon, sundayStart: false), mon);
    });
    test('Sunday still belongs to the week of the previous Monday', () {
      expect(startOfWeek(sun, sundayStart: false), DateTime(2026, 6, 29));
    });
  });

  group('startOfWeek (Sunday start)', () {
    test('Sunday is its own week start', () {
      expect(startOfWeek(sun, sundayStart: true), sun);
    });
    test('Saturday belongs to the week of the previous Sunday', () {
      expect(startOfWeek(sat, sundayStart: true), DateTime(2026, 6, 28));
    });
    test('Monday belongs to the week of the Sunday before it', () {
      expect(startOfWeek(mon, sundayStart: true), sun);
    });
  });

  group('monthLeadingBlanks', () {
    // July 2026 starts on a Wednesday (weekday 3).
    final DateTime july = DateTime(2026, 7, 1);
    test('Monday-start grid: Wednesday 1st needs 2 blanks', () {
      expect(monthLeadingBlanks(july, sundayStart: false), 2);
    });
    test('Sunday-start grid: Wednesday 1st needs 3 blanks', () {
      expect(monthLeadingBlanks(july, sundayStart: true), 3);
    });
    // November 2026 starts on a Sunday (weekday 7).
    final DateTime nov = DateTime(2026, 11, 1);
    test('Monday-start grid: Sunday 1st needs 6 blanks', () {
      expect(monthLeadingBlanks(nov, sundayStart: false), 6);
    });
    test('Sunday-start grid: Sunday 1st needs 0 blanks', () {
      expect(monthLeadingBlanks(nov, sundayStart: true), 0);
    });
  });

  test('header letters', () {
    expect(weekdayHeaderLetters(sundayStart: false).first, 'M');
    expect(weekdayHeaderLetters(sundayStart: true).first, 'S');
  });
}
